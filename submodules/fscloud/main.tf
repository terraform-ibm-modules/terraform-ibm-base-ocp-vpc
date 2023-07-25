

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
  use_existing_cos                = true
  existing_cos_id                 = var.existing_cos_id
  tags                            = var.tags
  kms_config                      = var.kms_config

}
