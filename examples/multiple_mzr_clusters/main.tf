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

locals {
  public_gateway = {
    zone-1 = true
    zone-2 = true
    zone-3 = false
  }
  addresses = {
    zone-1 = ["10.10.10.0/24"]
    zone-2 = ["10.20.10.0/24"]
    zone-3 = ["10.30.10.0/24"]
  }
  subnets = {
    zone-1 = [
      {
        acl_name = "vpc-acl"
        name     = "zone-1"
        cidr     = "10.10.10.0/24"
      }
    ],
    zone-2 = [
      {
        acl_name = "vpc-acl"
        name     = "zone-2"
        cidr     = "10.20.10.0/24"
      }
    ],
    zone-3 = [
      {
        acl_name = "vpc-acl"
        name     = "zone-3"
        cidr     = "10.30.10.0/24"
      }
    ]
  }

  cluster_vpc_subnets = {
    zone-1 = [{
      id         = module.vpc.subnet_zone_list[0].id
      zone       = module.vpc.subnet_zone_list[0].zone
      cidr_block = module.vpc.subnet_zone_list[0].cidr
      }
    ],
    zone-2 = [{
      id         = module.vpc.subnet_zone_list[1].id
      zone       = module.vpc.subnet_zone_list[1].zone
      cidr_block = module.vpc.subnet_zone_list[1].cidr
      }
    ],
    zone-3 = [{
      id         = module.vpc.subnet_zone_list[2].id
      zone       = module.vpc.subnet_zone_list[2].zone
      cidr_block = module.vpc.subnet_zone_list[2].cidr
      }
    ]
  }
}

module "vpc" {
  source              = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=v4.0.0"
  resource_group_id   = module.resource_group.resource_group_id
  region              = var.region
  prefix              = var.prefix
  tags                = var.resource_tags
  name                = var.vpc_name
  address_prefixes    = local.addresses
  subnets             = local.subnets
  use_public_gateways = local.public_gateway
}

###############################################################################
# Base OCP Clusters
###############################################################################

module "ocp_base_cluster_1" {
  source               = "../.."
  cluster_name         = "${var.prefix}-cluster-1"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_vpc_subnets
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
  vpc_subnets          = local.cluster_vpc_subnets
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
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=v2.2.0"
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
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents.git?ref=v1.0.2"
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
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents.git?ref=v1.0.2"
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
