##############################################################################
# Provision an OCP cluster with one extra worker pool inside a VPC
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

###############################################################################
# VPC
###############################################################################

module "vpc" {
  source              = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version             = "7.2.0"
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
# Security Group Rules addition.
##############################################################################

# Kube-<vpc id> Security Group
data "ibm_is_security_group" "kube_vpc_sg" {
  name = "kube-${module.ocp_base.vpc_id}"
}

resource "ibm_is_security_group_rule" "kube_vpc_rules" {

  for_each  = { for rule in var.sg_rules_vpc : rule.name => rule }
  group     = data.ibm_is_security_group.kube_vpc_sg.id
  direction = each.value.direction
  remote    = each.value.remote

  dynamic "tcp" {
    for_each = each.value.tcp == null ? [] : [each.value]
    content {
      port_min = each.value.tcp.port_min
      port_max = each.value.tcp.port_max
    }
  }

  dynamic "udp" {
    for_each = each.value.udp == null ? [] : [each.value]
    content {
      port_min = each.value.udp.port_min
      port_max = each.value.udp.port_max
    }
  }

  dynamic "icmp" {
    for_each = each.value.icmp == null ? [] : [each.value]
    content {
      type = lookup(each.value.icmp, "type", null)
      code = lookup(each.value.icmp, "code", null)
    }
  }
}

# Kube-<cluster id> Security Group
data "ibm_is_security_group" "kube_cluster_sg" {
  name = "kube-${module.ocp_base.cluster_id}"
}

resource "ibm_is_security_group_rule" "kube_cluster_rules" {

  for_each  = { for rule in var.sg_rules_cluster : rule.name => rule }
  group     = data.ibm_is_security_group.kube_cluster_sg.id
  direction = each.value.direction
  remote    = each.value.remote

  dynamic "tcp" {
    for_each = each.value.tcp == null ? [] : [each.value]
    content {
      port_min = each.value.tcp.port_min
      port_max = each.value.tcp.port_max
    }
  }

  dynamic "udp" {
    for_each = each.value.udp == null ? [] : [each.value]
    content {
      port_min = each.value.udp.port_min
      port_max = each.value.udp.port_max
    }
  }

  dynamic "icmp" {
    for_each = each.value.icmp == null ? [] : [each.value]
    content {
      type = lookup(each.value.icmp, "type", null)
      code = lookup(each.value.icmp, "code", null)
    }
  }
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
  source               = "../.."
  cluster_name         = var.prefix
  ibmcloud_api_key     = var.ibmcloud_api_key
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = module.vpc.subnet_detail_map
  worker_pools         = var.worker_pools
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  kms_config = {
    instance_id = module.kp_all_inclusive.key_protect_guid
    crk_id      = module.kp_all_inclusive.keys["ocp.${var.prefix}-cluster-key"].key_id
  }
}

##############################################################################
