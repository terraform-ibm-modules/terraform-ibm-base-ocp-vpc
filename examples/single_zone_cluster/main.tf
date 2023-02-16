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
# VPC ACLs
###############################################################################
# PRATEEK TBD: Check for equivalent public repo
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

###############################################################################
# VPC
###############################################################################

module "vpc" {
  source            = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=v3.0.0"
  resource_group_id = var.resource_group != null ? data.ibm_resource_group.existing_resource_group[0].id : ibm_resource_group.resource_group[0].id
  region            = var.region
  prefix            = var.prefix
  tags              = var.resource_tags
  name              = var.prefix
  use_public_gateways = {
    zone-1 = false
    zone-2 = false
    zone-3 = false
  }
}
#module "vpc" {
#source                      = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=v3.0.0"
#for_each                    = local.vpc_map
#name                        = each.value.prefix
#tags                        = var.tags
#resource_group_id           = each.value.resource_group == null ? null : local.resource_groups[each.value.resource_group]
#region                      = var.region
#prefix                      = var.prefix
#   network_cidr                = var.network_cidr
#   classic_access              = each.value.classic_access
#   use_manual_address_prefixes = each.value.use_manual_address_prefixes
#   default_network_acl_name    = each.value.default_network_acl_name
#   default_security_group_name = each.value.default_security_group_name
#   security_group_rules        = each.value.default_security_group_rules == null ? [] : each.value.default_security_group_rules
#   default_routing_table_name  = each.value.default_routing_table_name
#   address_prefixes            = each.value.address_prefixes
#   network_acls                = each.value.network_acls
#   use_public_gateways         = each.value.use_public_gateways
#   subnets                     = each.value.subnets
# }

# module "vpc" {
#     # source = "git::https://github.ibm.com/GoldenEye/vpc-module.git?ref=5.3.0"
#     source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=3.0.0"
#     name = var.prefix
#     region = var.region
#     resource_group_id = module.resource_group.resource_group_id

# }

# Identifying CIDR info and VPC data from public repo
# ACL info recheck if available in public github else find out how to use

###############################################################################
# Base OCP Single Zone Cluster
###############################################################################

locals {
  # Determine which zones to provision cluster in based on var.cluster_zone_list
  cluster_zones = formatlist("${var.region}-%s", var.cluster_zone_list)
  cluster_vpc_subnets = {
    private = [
      for zone in module.vpc.subnets.private : {
        id         = zone.id
        zone       = zone.zone
        cidr_block = zone.cidr_block
      } if contains(local.cluster_zones, zone.zone)
    ],
    edge = [
      for zone in module.vpc.subnets.edge : {
        id         = zone.id
        zone       = zone.zone
        cidr_block = zone.cidr_block
      } if contains(local.cluster_zones, zone.zone)
    ],
    transit = [
      for zone in module.vpc.subnets.transit : {
        id         = zone.id
        zone       = zone.zone
        cidr_block = zone.cidr_block
      } if contains(local.cluster_zones, zone.zone)
    ]
  }
}

module "ocp_base" {
  source               = "../.."
  ibmcloud_api_key     = var.ibmcloud_api_key
  cluster_name         = var.prefix
  ocp_version          = var.ocp_version
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_vpc_subnets
  tags                 = var.resource_tags
}

##############################################################################