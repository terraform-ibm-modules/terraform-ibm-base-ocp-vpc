##############################################################################
# Provision an OCP cluster with one extra "edge" worker pool inside a VPC
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

module "acl_profile" {
  source = "git::https://github.ibm.com/GoldenEye/acl-profile-ocp.git?ref=1.1.2"
}

locals {
  acl_rules_map = {
    private = concat(
      module.acl_profile.base_acl,
      module.acl_profile.https_acl,
      module.acl_profile.deny_all_acl
    )
  }
  vpc_cidr_bases = {
    private = "192.168.0.0/20",
    transit = "192.168.16.0/20",
    edge    = "192.168.32.0/20"
  }
}

module "vpc" {
  source                    = "git::https://github.ibm.com/GoldenEye/vpc-module.git?ref=5.3.0"
  unique_name               = var.prefix
  ibm_region                = var.region
  resource_group_id         = module.resource_group.resource_group_id
  cidr_bases                = local.vpc_cidr_bases
  acl_rules_map             = local.acl_rules_map
  virtual_private_endpoints = {}
  vpc_tags                  = var.resource_tags
}

##############################################################################
# KMS
##############################################################################
resource "ibm_resource_instance" "kms_instance" {
  name              = "${var.prefix}-kms"
  service           = "kms"
  plan              = "tiered-pricing"
  location          = var.region
  resource_group_id = module.resource_group.resource_group_id
  tags              = var.resource_tags
}

resource "ibm_kms_key" "kube_key" {
  instance_id  = ibm_resource_instance.kms_instance.guid
  key_name     = "kube-key-${var-prefix}"
  standard_key = false
}

##############################################################################
# Base OCP Cluster
##############################################################################
module "ocp_base" {
  source               = "../.."
  cluster_name         = var.prefix
  ibmcloud_api_key     = var.ibmcloud_api_key
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = module.vpc.subnets
  worker_pools         = var.worker_pools
  worker_pools_taints  = var.worker_pools_taints
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  kms_config = {
    instance_id = ibm_resource_instance.kms_instance.guid
    crk_id      = ibm_kms_key.kube_key.key_id
  }
}

##############################################################################