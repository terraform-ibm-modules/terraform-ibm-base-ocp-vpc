##############################################################################
# Provision an OCP cluster with one extra worker pool inside a VPC
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

###############################################################################
# VPC
###############################################################################

module "vpc" {
  source              = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version             = "7.4.0"
  resource_group_id   = module.resource_group.resource_group_id
  region              = var.region
  prefix              = var.prefix
  tags                = var.resource_tags
  name                = var.vpc_name
  address_prefixes    = var.addresses
  subnets             = var.subnets
  use_public_gateways = var.public_gateway
}

##############################################################################
# Key Protect
##############################################################################

module "kp_all_inclusive" {
  source                    = "terraform-ibm-modules/key-protect-all-inclusive/ibm"
  version                   = "4.2.0"
  key_protect_instance_name = "${var.prefix}-kp-instance"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  resource_tags             = var.resource_tags
  key_map                   = { "ocp" = ["${var.prefix}-cluster-key"] }
}

##############################################################################
# Base OCP Cluster
##############################################################################
module "ocp_base" {
  source                          = "../.."
  cluster_name                    = var.prefix
  ibmcloud_api_key                = var.ibmcloud_api_key
  resource_group_id               = module.resource_group.resource_group_id
  region                          = var.region
  force_delete_storage            = true
  vpc_id                          = module.vpc.vpc_id
  vpc_subnets                     = module.vpc.subnet_detail_map
  worker_pools                    = var.worker_pools
  worker_pools_taints             = var.worker_pools_taints
  ocp_version                     = var.ocp_version
  disable_public_endpoint         = var.disable_public_endpoint
  verify_worker_network_readiness = var.verify_worker_network_readiness
  tags                            = var.resource_tags
  kms_config = {
    instance_id = module.kp_all_inclusive.key_protect_guid
    crk_id      = module.kp_all_inclusive.keys["ocp.${var.prefix}-cluster-key"].key_id
  }
}

##############################################################################
