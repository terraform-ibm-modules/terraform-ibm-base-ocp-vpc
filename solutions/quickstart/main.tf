#######################################################################################################################
# Resource Group
#######################################################################################################################
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.7"
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
  version             = "8.10.5"
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
      workers_per_zone = 1
      zones            = 2

    }
    small = {
      flavor           = "bx2.8x32"
      workers_per_zone = 1
      zones            = 3
    }
    medium = {
      flavor           = "bx2.8x32"
      workers_per_zone = 2
      zones            = 3
    }
    large = {
      flavor           = "bx2.16x64"
      workers_per_zone = 3
      zones            = 3
    }
  }

  selected = lookup(local.size_config, var.size, local.size_config[var.size])

  # Build the vpc_subnets for default pool
  cluster_vpc_subnets = {
    default = [
      for i in range(local.selected.zones) : {
        id         = module.vpc.subnet_zone_list[i].id
        cidr_block = module.vpc.subnet_zone_list[i].cidr
        zone       = module.vpc.subnet_zone_list[i].zone
      }
    ]
  }

  worker_pools = [
    {
      pool_name        = "default"
      machine_type     = local.selected.flavor
      operating_system = var.default_worker_pool_operating_system
      workers_per_zone = local.selected.workers_per_zone
      vpc_subnets      = local.cluster_vpc_subnets["default"]

    }
  ]
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################
module "ocp_base" {
  source                              = "../.."
  cluster_name                        = local.cluster_name
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  ocp_version                         = var.openshift_version
  ocp_entitlement                     = var.ocp_entitlement
  vpc_id                              = module.vpc.vpc_id
  vpc_subnets                         = local.cluster_vpc_subnets
  worker_pools                        = local.worker_pools
  disable_outbound_traffic_protection = var.allow_outbound_traffic
  access_tags                         = var.access_tags
  disable_public_endpoint             = !var.allow_public_access_to_cluster_management
  cluster_config_endpoint_type        = "default"
}
