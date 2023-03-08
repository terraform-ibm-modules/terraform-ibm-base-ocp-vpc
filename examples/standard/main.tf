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

locals {
  public_gateway = {
    zone-1 = true
    zone-2 = false
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
  key_name     = "kube-key-${var.prefix}"
  standard_key = false
}

##############################################################################
# Base OCP Cluster
##############################################################################
locals {
  cluster_vpc_subnets = {
    zone-1 = [{
      id         = module.vpc.subnet_zone_list[0].id
      zone       = module.vpc.subnet_zone_list[0].zone
      cidr_block = module.vpc.subnet_zone_list[0].cidr
    }],
    zone-2 = [{
      id         = module.vpc.subnet_zone_list[1].id
      zone       = module.vpc.subnet_zone_list[1].zone
      cidr_block = module.vpc.subnet_zone_list[1].cidr
    }],
    zone-3 = [{
      id         = module.vpc.subnet_zone_list[2].id
      zone       = module.vpc.subnet_zone_list[2].zone
      cidr_block = module.vpc.subnet_zone_list[2].cidr
    }]
  }
}

module "ocp_base" {
  source               = "../.."
  cluster_name         = var.prefix
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_vpc_subnets
  worker_pools         = var.worker_pools
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  kms_config = {
    instance_id = ibm_resource_instance.kms_instance.guid
    crk_id      = ibm_kms_key.kube_key.key_id
  }
}

##############################################################################
