##############################################################################
# Provision an OCP cluster using an existing COS instance.
##############################################################################

module "ocp_base" {
  source = "../.."
  providers = {
    ibm.access_tags = ibm.access_tags
  }
  ibmcloud_api_key     = var.ibmcloud_api_key
  ocp_version          = var.ocp_version
  region               = var.region
  tags                 = var.resource_tags
  cluster_name         = var.prefix
  resource_group_id    = var.resource_group
  force_delete_storage = true
  vpc_id               = var.vpc_id
  vpc_subnets          = var.vpc_subnets
  worker_pools         = var.worker_pools
  use_existing_cos     = true
  existing_cos_id      = var.existing_cos_id
  access_tags          = var.access_tags
}

##############################################################################
