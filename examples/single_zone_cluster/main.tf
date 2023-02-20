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
  source              = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=v3.0.0"
  resource_group_id   = module.resource_group.resource_group_id
  region              = var.region
  prefix              = var.prefix
  tags                = var.resource_tags
  name                = var.vpc_name
  address_prefixes    = var.address_prefix
  subnets             = var.subnets
  use_public_gateways = var.use_public_gateways
}

###############################################################################
# Base OCP Single Zone Cluster
###############################################################################
locals {
  cluster_zones = formatlist("${var.region}-%s", var.cluster_zone_list) # ["au-syd-1"]
  # cluster_vpc_subnets = {
  #   zone-1 = [
  #     for zone in module.vpc.subnet_zone_list[0] :
  #     {
  #       id         = zone.id
  #       zone       = zone.zone
  #       cidr_block = zone.cidr_block
  #     } if contains(local.cluster_zones, zone.zone)
  #   ],
  #   zone-2 = [
  #     for zone in module.vpc.subnet_zone_list[1] :
  #     {
  #       id         = zone.id
  #       zone       = zone.zone
  #       cidr_block = zone.cidr_block
  #     } if contains(local.cluster_zones, zone.zone)
  #   ],
  #   zone-3 = [
  #     for zone in module.vpc.subnet_zone_list[2] :
  #     {
  #       id         = zone.id
  #       zone       = zone.zone
  #       cidr_block = zone.cidr_block
  #     } if contains(local.cluster_zones, zone.zone)
  #   ]
  # }

  # cluster_vpc_subnets = {
  #   zone-1 = contains(local.cluster_zones, module.vpc.subnet_zone_list[0].zone) == true ? [
  #     {
  #       id         = module.vpc.subnet_zone_list[0].id
  #       zone       = module.vpc.subnet_zone_list[0].zone
  #       cidr_block = module.vpc.subnet_zone_list[0].cidr
  #     }
  #   ] : [],
  #   zone-2 = contains(local.cluster_zones, module.vpc.subnet_zone_list[1].zone) == true ? [
  #     {
  #       id         = module.vpc.subnet_zone_list[1].id
  #       zone       = module.vpc.subnet_zone_list[1].zone
  #       cidr_block = module.vpc.subnet_zone_list[1].cidr
  #     }
  #   ] : [],
  #   zone-3 = contains(local.cluster_zones, module.vpc.subnet_zone_list[2].zone) == true ? [
  #     {
  #       id         = module.vpc.subnet_zone_list[2].id
  #       zone       = module.vpc.subnet_zone_list[2].zone
  #       cidr_block = module.vpc.subnet_zone_list[2].cidr
  #     }
  #   ] : []

  # }

  #### WOrked but condition check is required to span the same zone across all subnets
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
  ibmcloud_api_key     = var.ibmcloud_api_key
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_vpc_subnets
  # worker_pools         = var.worker_pools
  # worker_pools_taints  = var.worker_pools_taints
  ocp_version = var.ocp_version
  tags        = var.resource_tags
}

##############################################################################