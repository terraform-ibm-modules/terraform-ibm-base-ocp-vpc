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
  sz_pool = [
    {
      subnet_prefix    = "zone-1"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
  }]
}

module "ocp_base" {
  source               = "../.."
  cluster_name         = var.prefix
  ibmcloud_api_key     = var.ibmcloud_api_key
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = module.vpc.subnet_detail_map
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  worker_pools         = local.sz_pool
}

##############################################################################
