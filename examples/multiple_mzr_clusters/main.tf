###############################################################################
# Resource Group
###############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

###############################################################################
# VPC
###############################################################################

module "vpc" {
  source              = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=v5.0.1"
  resource_group_id   = module.resource_group.resource_group_id
  region              = var.region
  prefix              = var.prefix
  tags                = var.resource_tags
  name                = var.vpc_name
  address_prefixes    = var.addresses
  subnets             = var.subnets
  use_public_gateways = var.public_gateway
}

###############################################################################
# Base OCP Clusters
###############################################################################

locals {
  cluster_1_vpc_subnets = {
    default = [
      for zone in module.vpc.subnet_detail_map :
      {
        id         = zone[0].id
        zone       = zone[0].zone
        cidr_block = zone[0].cidr_block
      }
    ]
  }

  cluster_2_vpc_subnets = {
    default = [
      for zone in module.vpc.subnet_detail_map :
      {
        id         = zone[1].id
        zone       = zone[1].zone
        cidr_block = zone[1].cidr_block
      }
    ]
  }

}

module "ocp_base_cluster_1" {
  source               = "../.."
  cluster_name         = "${var.prefix}-cluster-1"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_1_vpc_subnets
  worker_pools         = var.worker_pools
  worker_pools_taints  = var.worker_pools_taints
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  ibmcloud_api_key     = var.ibmcloud_api_key
}

module "ocp_base_cluster_2" {
  source               = "../.."
  cluster_name         = "${var.prefix}-cluster-2"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_2_vpc_subnets
  worker_pools         = var.worker_pools
  worker_pools_taints  = var.worker_pools_taints
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  ibmcloud_api_key     = var.ibmcloud_api_key
}

###############################################################################
# Init cluster config for helm and kubernetes providers
###############################################################################
data "ibm_container_cluster_config" "cluster_config_c1" {
  cluster_name_id   = module.ocp_base_cluster_1.cluster_id
  resource_group_id = module.ocp_base_cluster_1.resource_group_id
}

data "ibm_container_cluster_config" "cluster_config_c2" {
  cluster_name_id   = module.ocp_base_cluster_2.cluster_id
  resource_group_id = module.ocp_base_cluster_2.resource_group_id
}

##############################################################################
# Observability instances : Create logdna and sysdig instances.
##############################################################################

module "observability_instances" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=v2.5.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  resource_group_id          = module.resource_group.resource_group_id
  region                     = var.region
  logdna_plan                = "7-day"
  sysdig_plan                = "graduated-tier"
  activity_tracker_provision = false
  enable_platform_logs       = false
  enable_platform_metrics    = false
  logdna_instance_name       = "${var.prefix}-logdna"
  sysdig_instance_name       = "${var.prefix}-sysdig"
}

##############################################################################
# Observability agents
##############################################################################

module "observability_agents_1" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents.git?ref=v1.1.0"
  providers = {
    helm = helm.helm_cluster_1
  }
  cluster_id                = module.ocp_base_cluster_1.cluster_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  logdna_instance_name      = module.observability_instances.logdna_name
  logdna_ingestion_key      = module.observability_instances.logdna_ingestion_key
  sysdig_instance_name      = module.observability_instances.sysdig_name
  sysdig_access_key         = module.observability_instances.sysdig_access_key
}

module "observability_agents_2" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents.git?ref=v1.1.0"
  providers = {
    helm = helm.helm_cluster_2
  }
  cluster_id                = module.ocp_base_cluster_2.cluster_id
  cluster_resource_group_id = module.ocp_base_cluster_2.resource_group_id
  logdna_instance_name      = module.observability_instances.logdna_name
  logdna_ingestion_key      = module.observability_instances.logdna_ingestion_key
  sysdig_instance_name      = module.observability_instances.sysdig_name
  sysdig_access_key         = module.observability_instances.sysdig_access_key
}

##############################################################################
