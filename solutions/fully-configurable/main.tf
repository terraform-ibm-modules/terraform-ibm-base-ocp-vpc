#######################################################################################################################
# Resource Group
#######################################################################################################################
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  existing_resource_group_name = var.existing_resource_group_name
}

#######################################################################################################################
# KMS Key
#######################################################################################################################

module "existing_kms_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_instance_crn
}

module "existing_cluster_kms_key_crn_parser" {
  count   = var.existing_cluster_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_cluster_kms_key_crn
}

module "existing_boot_volume_kms_key_crn_parser" {
  count   = var.existing_boot_volume_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_boot_volume_kms_key_crn
}

locals {
  prefix                    = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  cluster_kms_region        = var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].region : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].region : null
  cluster_existing_kms_guid = var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].service_instance : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].service_instance : null
  cluster_kms_account_id    = var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].account_id : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].account_id : null
  cluster_kms_key_id        = var.existing_kms_instance_crn != null ? module.kms[0].keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].key_id : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].resource : null
  cluster_key_ring_name     = "${local.prefix}${var.cluster_key_ring_name}"
  cluster_key_name          = "${local.prefix}${var.cluster_key_name}"

  boot_volume_key_ring_name     = "${local.prefix}${var.boot_volume_key_ring_name}"
  boot_volume_key_name          = "${local.prefix}${var.boot_volume_key_name}"
  boot_volume_existing_kms_guid = var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].service_instance : var.existing_boot_volume_kms_key_crn != null ? module.existing_boot_volume_kms_key_crn_parser[0].service_instance : null
  boot_volume_kms_account_id    = var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].account_id : var.existing_boot_volume_kms_key_crn != null ? module.existing_boot_volume_kms_key_crn_parser[0].account_id : null
  boot_volume_kms_key_id        = var.existing_kms_instance_crn != null ? module.kms[0].keys[format("%s.%s", local.boot_volume_key_ring_name, local.boot_volume_key_name)].key_id : var.existing_boot_volume_kms_key_crn != null ? module.existing_boot_volume_kms_key_crn_parser[0].resource : null

  kms_config = var.kms_encryption_enabled_cluster ? {
    crk_id           = local.cluster_kms_key_id
    instance_id      = local.cluster_existing_kms_guid
    private_endpoint = var.kms_endpoint_type == "private" ? true : false
    account_id       = local.cluster_kms_account_id
  } : null
}


# KMS root key for cluster or boot volume
module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = (var.kms_encryption_enabled_boot_volume || var.kms_encryption_enabled_cluster) && var.existing_cluster_kms_key_crn == null ? 1 : 0
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.21.2"
  create_key_protect_instance = false
  region                      = local.cluster_kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    var.kms_encryption_enabled_cluster ? {
      key_ring_name     = local.cluster_key_ring_name
      existing_key_ring = false
      keys = [
        {
          key_name                 = local.cluster_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = var.force_delete_kms_key
        }
      ]
    } : null,
    var.kms_encryption_enabled_boot_volume ? {
      key_ring_name     = local.boot_volume_key_ring_name
      existing_key_ring = false
      keys = [
        {
          key_name                 = local.boot_volume_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = var.force_delete_kms_key
        }
      ]
    } : null
  ]
}

########################################################################################################################
# OCP VPC cluster
########################################################################################################################

# data "ibm_is_subnets" "vpc_subnets" {
#   # count = length(var.vpc_subnets) > 0 ? 0 : 1
#   vpc = var.existing_vpc_id
# }

data "ibm_is_subnet" "subnets" {
  count      = length(var.existing_subnet_ids)
  identifier = var.existing_subnet_ids[count.index]
}

locals {
  vpc_subnets = {
    "default" = [
      for i in range(length(var.existing_subnet_ids)) :
      {
        id         = data.ibm_is_subnet.subnets[i].id
        zone       = data.ibm_is_subnet.subnets[i].zone
        cidr_block = data.ibm_is_subnet.subnets[i].ipv4_cidr_block
      }
    ]
  }

  # validation to check if the subnet passed belong to the same vpc.

  worker_pools = concat([
    {
      subnet_prefix     = "default"
      pool_name         = "default"
      machine_type      = var.machine_type
      workers_per_zone  = var.workers_per_zone
      resource_group_id = module.resource_group.resource_group_id
      operating_system  = var.operating_system
      labels            = var.default_worker_pool_labels
      minSize           = var.default_pool_minimum_number_of_nodes
      secondary_storage = var.default_worker_pool_secondary_storage
      maxSize           = var.default_pool_maximum_number_of_nodes
      enableAutoscaling = var.enable_autoscaling_for_default_pool
      boot_volume_encryption_kms_config = {
        crk             = local.boot_volume_kms_key_id
        kms_instance_id = local.boot_volume_existing_kms_guid
        kms_account_id  = local.boot_volume_kms_account_id
      }
      additional_security_group_ids = var.additional_security_group_ids
    }
  ], var.worker_pools)
}

module "ocp_base" {
  source                                = "../.."
  resource_group_id                     = module.resource_group.resource_group_id
  region                                = var.region
  tags                                  = var.cluster_resource_tags
  cluster_name                          = try("${local.prefix}-${var.cluster_name}", var.cluster_name)
  force_delete_storage                  = var.force_delete_storage
  use_existing_cos                      = true
  existing_cos_id                       = var.existing_cos_instance_crn
  vpc_id                                = var.existing_vpc_id
  vpc_subnets                           = local.vpc_subnets
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
