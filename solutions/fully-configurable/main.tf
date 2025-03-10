#######################################################################################################################
# Local block
#######################################################################################################################

locals {
  prefix = var.prefix != null ? (var.prefix != "" ? var.prefix : null) : null
}

#######################################################################################################################
# Resource Group
#######################################################################################################################
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  existing_resource_group_name = var.existing_resource_group_name
}

########################################################################################################################
# Parse KMS info from given CRNs
########################################################################################################################

module "kms_instance_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_instance_crn
}

module "kms_cluster_key_crn_parser" {
  count   = var.existing_kms_cluster_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_cluster_key_crn
}

module "kms_boot_volume_key_crn_parser" {
  count   = local.boot_volume_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = local.boot_volume_key_crn
}

#######################################################################################################################
# KMS encryption key
#######################################################################################################################
locals {
  ocp_cluster_key_ring_name        = try("${local.prefix}-${var.ocp_cluster_key_ring_name}", var.ocp_cluster_key_ring_name)
  ocp_cluster_key_name             = try("${local.prefix}-${var.ocp_cluster_key_name}", var.ocp_cluster_key_name)
  ocp_cluster_boot_volume_key_name = try("${local.prefix}-${var.ocp_cluster_boot_volume_key_name}", var.ocp_cluster_boot_volume_key_name)

  boot_volume_key_crn = var.existing_kms_boot_volume_key_crn == null ? var.existing_kms_cluster_key_crn : var.existing_kms_boot_volume_key_crn
  create_new_kms_key  = var.existing_kms_cluster_key_crn == null && local.boot_volume_key_crn == null ? 1 : 0
  kms_region          = var.existing_kms_cluster_key_crn != null ? module.kms_cluster_key_crn_parser[0].region : module.kms_instance_crn_parser[0].region

  kms_instance_guid = var.existing_kms_cluster_key_crn != null ? module.kms_cluster_key_crn_parser[0].service_instance : module.kms_instance_crn_parser[0].service_instance
  crk_id            = var.existing_kms_cluster_key_crn != null ? module.kms_cluster_key_crn_parser[0].resource : module.kms[0].keys[format("%s.%s", local.ocp_cluster_key_ring_name, local.ocp_cluster_key_name)].key_id

  kms_instance_boot_volume_guid = local.boot_volume_key_crn != null ? module.kms_boot_volume_key_crn_parser[0].service_instance : module.kms_instance_crn_parser[0].service_instance
  boot_volume_crk_id            = local.boot_volume_key_crn != null ? module.kms_boot_volume_key_crn_parser[0].resource : module.kms[0].keys[format("%s.%s", local.ocp_cluster_key_ring_name, local.ocp_cluster_boot_volume_key_name)].key_id
}

module "kms" {
  count                       = local.create_new_kms_key
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.19.8"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name     = local.ocp_cluster_key_ring_name
      existing_key_ring = false
      keys = [
        {
          key_name                 = local.ocp_cluster_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        },
        {
          key_name                 = local.ocp_cluster_boot_volume_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}

########################################################################################################################
# OCP VPC cluster
########################################################################################################################
data "ibm_is_subnets" "vpc_subnets" {
  vpc = var.existing_vpc_id
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

  boot_volume_encryption_kms_config = {
    kms_instance_id = local.kms_instance_boot_volume_guid
    crk             = local.boot_volume_crk_id
  }

  worker_pools = [
    {
      subnet_prefix                     = "default"
      pool_name                         = "default"
      machine_type                      = var.machine_type
      workers_per_zone                  = var.number_worker_nodes
      operating_system                  = var.operating_system
      boot_volume_encryption_kms_config = local.boot_volume_encryption_kms_config
    }
  ]

  kms_config = {
    instance_id = local.kms_instance_guid
    crk_id      = local.crk_id
  }
}

module "ocp_base" {
  source                                = "../.."
  resource_group_id                     = module.resource_group.resource_group_id
  region                                = var.region
  tags                                  = var.resource_tags
  cluster_name                          = try("${local.prefix}-${var.cluster_name}", var.cluster_name)
  force_delete_storage                  = var.force_delete_storage
  use_existing_cos                      = true
  existing_cos_id                       = var.existing_cos_instance_crn
  vpc_id                                = var.existing_vpc_id
  vpc_subnets                           = local.cluster_vpc_subnets
  ocp_version                           = var.ocp_version
  worker_pools                          = local.worker_pools
  access_tags                           = var.access_tags
  ocp_entitlement                       = var.ocp_entitlement
  additional_lb_security_group_ids      = var.additional_lb_security_group_ids
  additional_vpe_security_group_ids     = var.additional_vpe_security_group_ids
  addons                                = var.addons
  allow_default_worker_pool_replacement = var.allow_default_worker_pool_replacement
  attach_ibm_managed_security_group     = var.attach_ibm_managed_security_group
  cluster_config_endpoint_type          = var.cluster_config_endpoint_type
  cbr_rules                             = var.cbr_rules
  cluster_ready_when                    = var.cluster_ready_when
  custom_security_group_ids             = var.custom_security_group_ids
  disable_outbound_traffic_protection   = var.disable_outbound_traffic_protection
  disable_public_endpoint               = var.disable_public_endpoint
  enable_ocp_console                    = var.enable_ocp_console
  ignore_worker_pool_size_changes       = var.ignore_worker_pool_size_changes
  kms_config                            = local.kms_config
  manage_all_addons                     = var.manage_all_addons
  number_of_lbs                         = var.number_of_lbs
  pod_subnet_cidr                       = var.pod_subnet_cidr
  service_subnet_cidr                   = var.service_subnet_cidr
  use_private_endpoint                  = var.use_private_endpoint
  verify_worker_network_readiness       = var.verify_worker_network_readiness
  worker_pools_taints                   = var.worker_pools_taints
}
