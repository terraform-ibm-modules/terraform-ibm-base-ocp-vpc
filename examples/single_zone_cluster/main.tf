###############################################################################
# Resource Group
###############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (i.e. null) create a new one using prefix
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
# Base OCP
###############################################################################
locals {
  addons = {
    "cluster-autoscaler" = "1.0.8"
  }

  cluster_vpc_subnets = {
    default = module.vpc.subnet_detail_map.zone-1
  }
  sz_pool = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
    },
    {
      subnet_prefix     = "default"
      pool_name         = "logging"
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      minSize           = 1
      maxSize           = 6
      enableAutoscaling = true
    },
    {
      subnet_prefix     = "default"
      pool_name         = "sample"
      machine_type      = "bx2.4x16"
      workers_per_zone  = 4
      minSize           = 1
      maxSize           = 6
      enableAutoscaling = true
    }
  ]
}

module "ocp_base" {
  source               = "../.."
  cluster_name         = var.prefix
  ibmcloud_api_key     = var.ibmcloud_api_key
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_vpc_subnets
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  worker_pools         = local.sz_pool
  addons               = local.addons
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_base.cluster_id
  resource_group_id = module.ocp_base.resource_group_id

}

##############################################################################
