#######################################################################################################################
# Resource Group
#######################################################################################################################
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.2.1"
  existing_resource_group_name = var.existing_resource_group_name
}

locals {
  prefix       = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  cluster_name = "${local.prefix}${var.cluster_name}"
}

########################################################################################################################
# VPC + Subnet + Public Gateway
########################################################################################################################
locals {
  octets = split(".", split("/", var.address_prefix)[0])
  mask   = split("/", var.address_prefix)[1]

  subnets = {
    for count in range(1, 4) :
    "zone-${count}" => count <= local.selected.zones ? [
      {
        name = "${local.prefix}subnet-${count}"
        cidr = format(
          "%d.%d.%d.0/%s",
          tonumber(local.octets[0]),
          tonumber(local.octets[1]) + (count - 1) * 10,
          tonumber(local.octets[2]),
          local.mask
        )
        public_gateway = true
        acl_name       = "${var.prefix}-acl"
      }
    ] : []
  }

  public_gateway = {
    for count in range(1, 4) :
    "zone-${count}" => count <= local.selected.zones
  }

  network_acl = {
    name                         = "${local.prefix}acl"
    add_ibm_cloud_internal_rules = true
    add_vpc_connectivity_rules   = true
    prepend_ibm_rules            = true
    rules = [{
      name        = "${local.prefix}inbound"
      action      = "allow"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      },
      {
        name        = "${local.prefix}outbound"
        action      = "allow"
        source      = "0.0.0.0/0"
        destination = "0.0.0.0/0"
        direction   = "outbound"
      }
    ]
  }
}

module "vpc" {
  source              = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version             = "7.25.10"
  resource_group_id   = module.resource_group.resource_group_id
  region              = var.region
  name                = "vpc"
  prefix              = var.prefix
  subnets             = local.subnets
  network_acls        = [local.network_acl]
  use_public_gateways = local.public_gateway
}

locals {
  size_config = {
    mini = {
      flavor           = "bx2.4x16"
      workers_per_zone = 2
      zones            = 2

    }
    small = {
      flavor           = "bx2.8x32"
      workers_per_zone = 3
      zones            = 3
    }
    medium = {
      flavor           = "bx2.8x32"
      workers_per_zone = 5
      zones            = 3
    }
    large = {
      flavor           = "bx2.16x64"
      workers_per_zone = 7
      zones            = 3
    }
  }

  selected = lookup(local.size_config, var.size, local.size_config[var.size])

  worker_pools = concat(
    [
      {
        subnet_prefix    = "zone-1"
        pool_name        = "default" # Exactly 'default' here
        machine_type     = local.selected.flavor
        workers_per_zone = local.selected.workers_per_zone
        operating_system = var.default_worker_pool_operating_system
      }
    ],
    [
      for count in range(2, local.selected.zones + 1) : {
        subnet_prefix    = "zone-${count}"
        pool_name        = "workerpool-${count}" # 'workerpool-2', 'workerpool-3', etc.
        machine_type     = local.selected.flavor
        workers_per_zone = local.selected.workers_per_zone
        operating_system = var.default_worker_pool_operating_system
      }
    ]
  )
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################
module "ocp_base" {
  source                              = "../.."
  cluster_name                        = local.cluster_name
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  ocp_version                         = var.ocp_version
  ocp_entitlement                     = var.ocp_entitlement
  vpc_id                              = module.vpc.vpc_id
  vpc_subnets                         = module.vpc.subnet_detail_map
  worker_pools                        = local.worker_pools
  disable_outbound_traffic_protection = var.disable_outbound_traffic_protection
  access_tags                         = var.access_tags
  disable_public_endpoint             = var.disable_public_endpoint
  use_private_endpoint                = var.use_private_endpoint
  cluster_config_endpoint_type        = var.cluster_config_endpoint_type
}
