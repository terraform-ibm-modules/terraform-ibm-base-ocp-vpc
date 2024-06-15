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
# VPC + Subnet + Public Gateway
#
# NOTE: This is a very simple VPC with single subnet in a single zone with a public gateway enabled, that will allow
# all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets and zones for resiliency, and
# ACLs/Security Groups for network security.
########################################################################################################################

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

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.id
}

########################################################################################################################
# OCP VPC cluster (single zone)
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
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2 # minimum of 2 is allowed when using single zone
    },
    {
      subnet_prefix                 = "default"
      pool_name                     = "custom-sg"
      machine_type                  = "bx2.4x16"
      workers_per_zone              = 2
      additional_security_group_ids = [module.custom_sg["custom-worker-pool-sg"].security_group_id]
    },
  ]
}

########################################################################################################################
# Security groups
# Creating some security group for illustration purpose in this example.
# Real-world sg would have your own rules set in the `security_group_rules` input.
########################################################################################################################

module "custom_sg" {
  for_each                     = toset(["custom-cluster-sg", "custom-worker-pool-sg", "custom-lb-sg", "custom-master-vpe-sg", "custom-registry-vpe-sg", "custom-kube-api-vpe-sg"])
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "2.6.2"
  add_ibm_cloud_internal_rules = false
  security_group_name          = each.key
  security_group_rules         = []
  resource_group               = module.resource_group.resource_group_id
  vpc_id                       = ibm_is_vpc.vpc.id
}


module "ocp_base" {
  source                            = "../.."
  ibmcloud_api_key                  = var.ibmcloud_api_key
  resource_group_id                 = module.resource_group.resource_group_id
  region                            = var.region
  tags                              = var.resource_tags
  cluster_name                      = var.prefix
  force_delete_storage              = true
  vpc_id                            = ibm_is_vpc.vpc.id
  vpc_subnets                       = local.cluster_vpc_subnets
  ocp_version                       = var.ocp_version
  worker_pools                      = local.worker_pools
  access_tags                       = var.access_tags
  attach_ibm_managed_security_group = true # true is the default
  custom_security_group_ids         = [module.custom_sg["custom-cluster-sg"].security_group_id]
  additional_lb_security_group_ids  = [module.custom_sg["custom-lb-sg"].security_group_id]
  additional_vpe_security_group_ids = {
    "master"   = [module.custom_sg["custom-master-vpe-sg"].security_group_id]
    "api"      = [module.custom_sg["custom-kube-api-vpe-sg"].security_group_id]
    "registry" = [module.custom_sg["custom-registry-vpe-sg"].security_group_id]
  }
}
