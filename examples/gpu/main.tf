########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC + Subnets + Public Gateways using landing-zone-vpc module
########################################################################################################################

module "vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "8.8.0"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = var.resource_tags
  name              = "${var.prefix}-vpc"

  # Define subnets across 3 zones for the default worker pool
  # and a separate subnet in zone 1 for the GPU worker pool
  subnets = {
    zone-1 = [
      {
        name           = "subnet-default-1"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      },
      {
        name           = "subnet-gpu"
        cidr           = "10.10.20.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ],
    zone-2 = [
      {
        name           = "subnet-default-2"
        cidr           = "10.20.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ],
    zone-3 = [
      {
        name           = "subnet-default-3"
        cidr           = "10.30.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ]
  }

  # Enable public gateways in all zones
  use_public_gateways = {
    zone-1 = true
    zone-2 = true
    zone-3 = true
  }

  # Define network ACLs
  network_acls = [
    {
      name                         = "vpc-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      rules                        = []
    }
  ]
}

########################################################################################################################
# OCP VPC cluster with default worker pool across 3 zones and a GPU worker pool in zone 1
########################################################################################################################

locals {
  # Get all subnets from the VPC module
  all_subnets = module.vpc.subnet_zone_list

  # Define subnets for the default worker pool (across 3 zones)
  default_vpc_subnets = {
    default = [
      for subnet in local.all_subnets :
      {
        id         = subnet.id
        cidr_block = subnet.cidr
        zone       = subnet.zone
      }
      if strcontains(subnet.name, "subnet-default")
    ]
  }

  # Define subnet for the GPU worker pool (single zone)
  gpu_vpc_subnets = {
    gpu = [
      for subnet in local.all_subnets :
      {
        id         = subnet.id
        cidr_block = subnet.cidr
        zone       = subnet.zone
      }
      if strcontains(subnet.name, "subnet-gpu") # Use strcontains rather than == given that a prefix is added by landing zone vpc to subnet names
    ]
  }

  # Combine all subnets
  cluster_vpc_subnets = merge(local.default_vpc_subnets, local.gpu_vpc_subnets)

  # Define worker pools
  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default"
      machine_type     = "bx2.4x16"
      workers_per_zone = 1
      operating_system = "RHCOS"
    },
    {
      subnet_prefix    = "gpu"
      pool_name        = "gpu"
      machine_type     = "gx3.16x80.l4"
      workers_per_zone = 1
      operating_system = "RHCOS"
    }
  ]
}

module "ocp_base" {
  source               = "../.."
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  tags                 = var.resource_tags
  cluster_name         = var.prefix
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_vpc_subnets
  ocp_version          = var.ocp_version
  worker_pools         = local.worker_pools
  access_tags          = var.access_tags
  ocp_entitlement      = var.ocp_entitlement
}
