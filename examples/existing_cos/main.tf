##############################################################################
#
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (i.e. null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

module "ocp_base" {
  source               = "../.."
  cluster_name         = var.prefix
  resource_group_id    = module.resource_group.resource_group_id
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
