#######################################################################################################################
# Resource Group
#######################################################################################################################
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_resource_group == false ? ((var.prefix != null && var.prefix != "") ? "${var.prefix}-${var.resource_group_name}" : var.resource_group_name) : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################

data "ibm_is_subnets" "vpc_subnets" {
  vpc = var.vpc_id
}

locals {
   cluster_vpc_subnets = {
    for subnet in data.ibm_is_subnets.vpc_subnets.subnets : 
    "default" => [{
      id         = subnet.id
      zone       = subnet.zone
      cidr_block = subnet.ipv4_cidr_block
    }]
  }

  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = var.machine-type
      workers_per_zone = var.number-worker-nodes
      operating_system = var.operating_system
    }
  ]
}

module "ocp_base" {
  source                               = "../.."
  resource_group_id                    = module.resource_group.resource_group_id
  region                               = var.region
  tags                                 = var.resource_tags
  cluster_name                         = var.prefix
  force_delete_storage                 = true
  vpc_id                               = var.vpc_id
  vpc_subnets                          = local.cluster_vpc_subnets
  ocp_version                          = var.ocp_version
  worker_pools                         = local.worker_pools
  access_tags                          = var.access_tags
  ocp_entitlement                      = var.ocp_entitlement
  disable_outbound_traffic_protection  = true
  import_default_worker_pool_on_create = false
}
