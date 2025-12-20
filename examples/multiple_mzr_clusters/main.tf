########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.7"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

########################################################################################################################
# Public gw in 2 zones
########################################################################################################################

resource "ibm_is_public_gateway" "gateway" {
  for_each       = toset(["1", "2"])
  name           = "${var.prefix}-gateway-${each.key}"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-${each.key}"
}

########################################################################################################################
# Subnets across the 2 zones
########################################################################################################################

resource "ibm_is_subnet" "subnet_cluster_1" {
  for_each                 = toset(["1", "2"])
  name                     = "${var.prefix}-subnet-1-${each.key}"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-${each.key}"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway[each.key].id
}

resource "ibm_is_subnet" "subnet_cluster_2" {
  for_each                 = toset(["1", "2"])
  name                     = "${var.prefix}-subnet-2-${each.key}"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-${each.key}"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway[each.key].id
}

########################################################################################################################
# 2 x multi zone (2 zone) OCP Clusters
########################################################################################################################

locals {

  # Choosing RHEL for the default worker pool will limit all additional worker pools to RHEL.
  # If we plan to use RHCOS with the cluster, we should create the default worker pool with RHCOS.

  os_rhcos  = "RHCOS"
  os_rhel_9 = "RHEL_9_64"
  cluster_1_vpc_subnets = {
    default = [
      for subnet in ibm_is_subnet.subnet_cluster_1 :
      {
        id         = subnet.id
        zone       = subnet.zone
        cidr_block = subnet.ipv4_cidr_block
      }
    ]
  }

  cluster_2_vpc_subnets = {
    default = [
      for subnet in ibm_is_subnet.subnet_cluster_2 :
      {
        id         = subnet.id
        zone       = subnet.zone
        cidr_block = subnet.ipv4_cidr_block
      }
    ]
  }

  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names standard pool "standard" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      operating_system = local.os_rhcos
    },
    {
      subnet_prefix    = "default"
      pool_name        = "logging-worker-pool"
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      labels           = { "dedicated" : "logging-worker-pool" }
      operating_system = local.os_rhel_9
    }
  ]

  worker_pool_taints = {
    all = []
    logging-worker-pool = [{
      key    = "dedicated"
      value  = "logging-worker-pool"
      effect = "NoExecute"
    }]
    default = []
  }
}

module "ocp_base_cluster_1" {
  source                              = "../.."
  cluster_name                        = "${var.prefix}-cluster-1"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  force_delete_storage                = true
  vpc_id                              = ibm_is_vpc.vpc.id
  vpc_subnets                         = local.cluster_1_vpc_subnets
  disable_outbound_traffic_protection = true
  worker_pools                        = local.worker_pools
  worker_pools_taints                 = local.worker_pool_taints
  ocp_version                         = var.ocp_version
  tags                                = var.resource_tags
  ocp_entitlement                     = var.ocp_entitlement
}

module "ocp_base_cluster_2" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source            = "terraform-ibm-modules/base-ocp-vpc/ibm"
  # version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  cluster_name                        = "${var.prefix}-cluster-2"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  force_delete_storage                = true
  vpc_id                              = ibm_is_vpc.vpc.id
  disable_outbound_traffic_protection = true
  vpc_subnets                         = local.cluster_2_vpc_subnets
  worker_pools                        = local.worker_pools
  worker_pools_taints                 = local.worker_pool_taints
  ocp_version                         = var.ocp_version
  tags                                = var.resource_tags
  ocp_entitlement                     = var.ocp_entitlement
}

########################################################################################################################
# Init cluster config for helm and kubernetes providers
########################################################################################################################

data "ibm_container_cluster_config" "cluster_config_c1" {
  cluster_name_id   = module.ocp_base_cluster_1.cluster_id
  resource_group_id = module.ocp_base_cluster_1.resource_group_id
  config_dir        = "${path.module}/../../kubeconfig"
}

data "ibm_container_cluster_config" "cluster_config_c2" {
  cluster_name_id   = module.ocp_base_cluster_2.cluster_id
  resource_group_id = module.ocp_base_cluster_2.resource_group_id
  config_dir        = "${path.module}/../../kubeconfig"
}

########################################################################################################################
# Cloud monitoring instance
########################################################################################################################

module "monitoring_instance" {
  source                  = "terraform-ibm-modules/cloud-monitoring/ibm"
  version                 = "1.12.2"
  resource_group_id       = module.resource_group.resource_group_id
  region                  = var.region
  plan                    = "graduated-tier"
  enable_platform_metrics = false
  instance_name           = "${var.prefix}-mon"
}

########################################################################################################################
# Cloud monitoring agents
########################################################################################################################

module "monitoring_agent_1" {
  providers = {
    helm = helm.helm_cluster_1
  }
  source                    = "terraform-ibm-modules/monitoring-agent/ibm"
  version                   = "1.19.2"
  cluster_id                = module.ocp_base_cluster_1.cluster_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  access_key                = module.monitoring_instance.access_key
  instance_region           = var.region
}

module "monitoring_agent_2" {
  providers = {
    helm = helm.helm_cluster_2
  }
  source                    = "terraform-ibm-modules/monitoring-agent/ibm"
  version                   = "1.19.2"
  cluster_id                = module.ocp_base_cluster_2.cluster_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  access_key                = module.monitoring_instance.access_key
  instance_region           = var.region
}
