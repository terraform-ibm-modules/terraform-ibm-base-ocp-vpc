

module "fscloud" {
  source = "../.."

  cluster_name                          = var.cluster_name
  resource_group_id                     = var.resource_group_id
  region                                = var.region
  force_delete_storage                  = var.force_delete_storage
  ocp_version                           = var.ocp_version
  ocp_entitlement                       = var.ocp_entitlement
  vpc_id                                = var.vpc_id
  vpc_subnets                           = var.vpc_subnets
  use_private_endpoint                  = var.use_private_endpoint
  worker_pools                          = var.worker_pools
  disable_public_endpoint               = true
  cluster_config_endpoint_type          = var.cluster_config_endpoint_type
  cluster_ready_when                    = var.cluster_ready_when
  ignore_worker_pool_size_changes       = var.ignore_worker_pool_size_changes
  verify_worker_network_readiness       = var.verify_worker_network_readiness
  worker_pools_taints                   = var.worker_pools_taints
  use_existing_cos                      = true
  existing_cos_id                       = var.existing_cos_id
  tags                                  = var.tags
  kms_config                            = var.kms_config
  addons                                = var.addons
  access_tags                           = var.access_tags
  import_default_worker_pool_on_create  = var.import_default_worker_pool_on_create
  allow_default_worker_pool_replacement = var.allow_default_worker_pool_replacement
  attach_ibm_managed_security_group     = var.attach_ibm_managed_security_group
  custom_security_group_ids             = var.custom_security_group_ids
  additional_lb_security_group_ids      = var.additional_lb_security_group_ids
  number_of_lbs                         = var.number_of_lbs
  additional_vpe_security_group_ids     = var.additional_vpe_security_group_ids
  operating_system                      = var.operating_system
  cbr_rules                             = var.cbr_rules
}
