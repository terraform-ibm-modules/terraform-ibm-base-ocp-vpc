##############################################################################
# Provision an OCP cluster with one extra worker pool inside a VPC
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Create a VPC with three subnets, across AZ zones, and public gateway in zone 1 only.
# NOTE: this is a very simple VPC/Subnet configuration for example purposes only,
# that will allow all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets
# and zones for resiliency, and ACLs/Security Groups for network security.
##############################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnets" {
  for_each                 = toset(["1", "2", "3"])
  name                     = "${var.prefix}-subnet-${each.key}"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-${each.key}"
  total_ipv4_address_count = 256
  # for this example, gateway only goes on zone 1
  public_gateway = (each.key == "1") ? ibm_is_public_gateway.gateway.id : null
}

##############################################################################
# Key Protect
##############################################################################

module "kp_all_inclusive" {
  source                    = "terraform-ibm-modules/key-protect-all-inclusive/ibm"
  version                   = "4.3.0"
  key_protect_instance_name = "${var.prefix}-kp-instance"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  resource_tags             = var.resource_tags
  key_map                   = { "ocp" = ["${var.prefix}-cluster-key"] }
}

locals {
  cluster_vpc_subnets = {
    for zone_name in distinct([
      for subnet in ibm_is_subnet.subnets :
      subnet.zone
    ]) :
    "zone-${substr(zone_name, -1, length(zone_name))}" => [
      for subnet in ibm_is_subnet.subnets :
      {
        id         = subnet.id
        zone       = subnet.zone
        cidr_block = subnet.ipv4_cidr_block
        crn        = subnet.crn
      } if subnet.zone == zone_name
    ]
  }
}

##############################################################################
# Base OCP Cluster
##############################################################################
module "ocp_base" {
  source                          = "../.."
  cluster_name                    = var.prefix
  ibmcloud_api_key                = var.ibmcloud_api_key
  resource_group_id               = module.resource_group.resource_group_id
  region                          = var.region
  force_delete_storage            = true
  vpc_id                          = ibm_is_vpc.vpc.id
  vpc_subnets                     = local.cluster_vpc_subnets
  worker_pools                    = var.worker_pools
  worker_pools_taints             = var.worker_pools_taints
  ocp_version                     = var.ocp_version
  disable_public_endpoint         = var.disable_public_endpoint
  verify_worker_network_readiness = var.verify_worker_network_readiness
  tags                            = var.resource_tags
  kms_config = {
    instance_id = module.kp_all_inclusive.key_protect_guid
    crk_id      = module.kp_all_inclusive.keys["ocp.${var.prefix}-cluster-key"].key_id
  }
}

##############################################################################
