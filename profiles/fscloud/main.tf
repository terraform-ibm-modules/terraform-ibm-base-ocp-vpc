locals {
  #  Validation
  # tflint-ignore: terraform_unused_declarations
  #  validate_different_regions = var.primary_region == var.secondary_region ? tobool("primary and secondary bucket regions must not match") : true
}

resource "ibm_iam_authorization_policy" "kms_policy" {
  count               = var.skip_iam_authorization_policy ? 0 : 1
  source_service_name = "containers-kubernetes"
  #  TODO: Restrict scope as much as possible. Support case open(CS3338005) to investigate why it cannot be applied to the resource group
  #  source_resource_group_id    = var.resource_group_id
  target_service_name         = "hs-crypto"
  target_resource_instance_id = var.kms_config.instance_id
  roles                       = ["Reader"]
}

module "fscloud" {
  source = "../.."

  ibmcloud_api_key                = var.ibmcloud_api_key
  cluster_name                    = var.cluster_name
  resource_group_id               = var.resource_group_id
  region                          = var.region
  force_delete_storage            = var.force_delete_storage
  ocp_version                     = var.ocp_version
  ocp_entitlement                 = var.ocp_entitlement
  vpc_id                          = var.vpc_id
  vpc_subnets                     = var.vpc_subnets
  worker_pools                    = var.worker_pools
  disable_public_endpoint         = true
  cluster_ready_when              = var.cluster_ready_when
  ignore_worker_pool_size_changes = var.ignore_worker_pool_size_changes
  verify_worker_network_readiness = var.verify_worker_network_readiness
  worker_pools_taints             = var.worker_pools_taints
  cos_name                        = var.cos_name
  use_existing_cos                = var.use_existing_cos
  existing_cos_id                 = var.existing_cos_id
  tags                            = var.tags
  kms_config                      = var.kms_config

}
