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
# Security Group Rules
###############################################################################

# Retrieve information of an existing security group as a read-only data source.
data "ibm_security_group" "get_vpc_sg" {
  description = "ID of the clusters VPC"
  name        = "kube-${module.ocp_base.vpc_id}"
}

data "ibm_security_group" "get_vpc_cluster_sg" {
  description = "ID of cluster created"
  name        = "kube-${module.ocp_base.cluster_id}"
}

# locals {
#   security_group_rules = toset(["allow_ssh", "allow_http", "allow_https", "allow_all", "allow_outbound"])
# }

# data "ibm_security_group" "get_vpc_sg_all" {
#   for_each    = local.security_group_rules
#   description = "ID of the clusters VPC"
#   # name             = "kube-${module.ocp_base.vpc_id}"
#   name = each.value
# }

data "ibm_security_group" "allow_ssh" {
  description = "Allow SSH Rule"
  # name             = "kube-${module.ocp_base.cluster_id}"
  name = "allow_ssh"
}


#Create, delete, and update a rule for a security group
# Cusomtize the rule and attach it with a security group id
# kube-<clusterId> and kube-<vpcid> SG
# resource "ibm_security_group_rule" "allow_port_8080" {
#     direction = "ingress"
#     ether_type = "IPv4"
#     port_range_min = 8080
#     port_range_max = 8080
#     protocol = "tcp"
#     security_group_id = data.ibm_security_group.get_vpc_sg.id
# }

###############################################################################
# VPC
###############################################################################

module "vpc" {
  source              = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=v4.1.0"
  resource_group_id   = module.resource_group.resource_group_id
  region              = var.region
  prefix              = var.prefix
  tags                = var.resource_tags
  name                = var.vpc_name
  address_prefixes    = var.addresses
  subnets             = var.subnets
  use_public_gateways = var.public_gateway
  # security_group_rules =
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
  key_map                   = { "ocp" = ["${var.prefix}-cluster-key"] }
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
  ibmcloud_api_key     = var.ibmcloud_api_key
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_vpc_subnets
  worker_pools         = var.worker_pools
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  kms_config = {
    instance_id = module.kp_all_inclusive.key_protect_guid
    crk_id      = module.kp_all_inclusive.keys["ocp.${var.prefix}-cluster-key"].key_id
  }
}

##############################################################################
