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


module "worker_pools" {
  source            = "../../modules/worker-pool"
  resource_group_id = module.resource_group.resource_group_id
  cluster_id        = var.cluster_id
  worker_pools      = var.worker_pools
  vpc_subnets       = var.vpc_subnets
  vpc_id            = var.vpc_id
}
