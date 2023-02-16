##############################################################################
# 
##############################################################################

module "ocp_base" {
  source       = "../.."
  cluster_name = var.prefix
  # resource_group_id = var.resource_group
  region               = var.region
  force_delete_storage = true
  vpc_id               = var.vpc_id
  vpc_subnets          = var.vpc_subnets
  existing_cos_id      = var.existing_cos_id
  tags                 = var.resource_tags
  ocp_version          = var.ocp_version
  ibmcloud_api_key     = var.ibmcloud_api_key
}

##############################################################################
