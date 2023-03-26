##############################################################################
# Provision an OCP cluster with one extra worker pool inside a VPC
##############################################################################

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

##############################################################################
# Key Protect
##############################################################################

module "kp_all_inclusive" {
  source                    = "git::https://github.com/terraform-ibm-modules/terraform-ibm-key-protect-all-inclusive.git?ref=v4.0.0"
  key_protect_instance_name = "${var.prefix}-kp-instance"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  resource_tags             = var.resource_tags
  key_map = { "ocp" = [
    "${var.prefix}-cluster-key",
    "${var.prefix}-default-pool-boot-volume-encryption-key",
    "${var.prefix}-other-pool-boot-volume-encryption-key"
  ] }
}

##############################################################################
# Base OCP Cluster
##############################################################################
locals {
  worker_pools = [
    {
      subnet_prefix     = "zone-1"
      pool_name         = "default" # ibm_container_vpc_cluster automatically names standard pool "standard" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      labels            = {}
      resource_group_id = module.resource_group.resource_group_id
      boot_volume_encryption_kms_config = {
        crk             = module.kp_all_inclusive.keys["ocp.${var.prefix}-default-pool-boot-volume-encryption-key"].key_id
        kms_instance_id = module.kp_all_inclusive.key_protect_guid
      }
    },
    {
      subnet_prefix     = "zone-2"
      pool_name         = "zone-2"
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      labels            = {}
      resource_group_id = module.resource_group.resource_group_id
      boot_volume_encryption_kms_config = {
        crk             = module.kp_all_inclusive.keys["ocp.${var.prefix}-other-pool-boot-volume-encryption-key"].key_id
        kms_instance_id = module.kp_all_inclusive.key_protect_guid
      }
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
  vpc_subnets          = module.vpc.subnet_detail_map
  worker_pools         = length(var.worker_pools) > 0 ? var.worker_pools : tolist(local.worker_pools)
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  kms_config = {
    instance_id = module.kp_all_inclusive.key_protect_guid
    crk_id      = module.kp_all_inclusive.keys["ocp.${var.prefix}-cluster-key"].key_id
  }
}

##############################################################################
