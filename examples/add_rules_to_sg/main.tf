########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

########################################################################################################################
# Public Gateway in zone-1
########################################################################################################################

resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

########################################################################################################################
# Subnet in zone-1
########################################################################################################################

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.id
}

########################################################################################################################
# Security Group Rules addition
########################################################################################################################

locals {
  standard_cluster_allow_rules = [
    { name = "allow-port-8080", direction = "inbound", tcp = { port_max = 8080, port_min = 8080 }, udp = null, icmp = null, remote = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block },
    { name = "allow-port-443", direction = "inbound", tcp = { port_max = 443, port_min = 443 }, udp = null, icmp = null, remote = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block },
    { name = "udp-range", direction = "inbound", udp = { port_max = 30103, port_min = 30103 }, tcp = null, icmp = null, remote = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block },
  ]
  vpc_security_group = [for group in data.ibm_is_security_groups.vpc_security_groups.security_groups : group if startswith(group.name, "kube-") && endswith(group.name, module.ocp_base.vpc_id)][0]
}

data "ibm_is_security_groups" "vpc_security_groups" {
  vpc_id = module.ocp_base.vpc_id
}

# Kube-<vpc id> Security Group
data "ibm_is_security_group" "kube_vpc_sg" {
  name = local.vpc_security_group.name
}

resource "ibm_is_security_group_rule" "kube_vpc_rules" {

  for_each  = { for rule in local.standard_cluster_allow_rules : rule.name => rule }
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

  for_each  = { for rule in local.standard_cluster_allow_rules : rule.name => rule }
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

########################################################################################################################
# OCP VPC single zone cluster
########################################################################################################################

locals {
  cluster_vpc_subnets = {
    default = [
      {
        id         = ibm_is_subnet.subnet_zone_1.id
        cidr_block = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_1.zone
      }
    ]
  }

  worker_pools = [
    {
      subnet_prefix     = "default"
      pool_name         = "default" # ibm_container_vpc_cluster automatically names standard pool "standard" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      labels            = {}
      resource_group_id = module.resource_group.resource_group_id
    }
  ]
}

module "ocp_base" {
  source               = "../.."
  cluster_name         = var.prefix
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = ibm_is_vpc.vpc.id
  vpc_subnets          = local.cluster_vpc_subnets
  worker_pools         = local.worker_pools
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
}
