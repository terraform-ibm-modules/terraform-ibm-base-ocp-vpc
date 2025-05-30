#######################################################################################################################
# Resource Group
#######################################################################################################################
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.2.0"
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
  cluster_name              = "${local.prefix}${var.cluster_name}"
  cluster_kms_region        = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_cluster ? module.existing_kms_crn_parser[0].region : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].region : null
  cluster_existing_kms_guid = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_cluster ? module.existing_kms_crn_parser[0].service_instance : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].service_instance : null
  cluster_kms_account_id    = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_cluster ? module.existing_kms_crn_parser[0].account_id : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].account_id : null
  cluster_kms_key_id        = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_cluster ? module.kms[0].keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].key_id : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].resource : null
  cluster_key_ring_name     = "${local.prefix}${var.cluster_kms_key_ring_name}"
  cluster_key_name          = "${local.prefix}${var.cluster_kms_key_name}"

  boot_volume_key_ring_name     = "${local.prefix}${var.boot_volume_kms_key_ring_name}"
  boot_volume_key_name          = "${local.prefix}${var.boot_volume_kms_key_name}"
  boot_volume_existing_kms_guid = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_boot_volume ? module.existing_kms_crn_parser[0].service_instance : var.existing_boot_volume_kms_key_crn != null ? module.existing_boot_volume_kms_key_crn_parser[0].service_instance : null
  boot_volume_kms_account_id    = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_boot_volume ? module.existing_kms_crn_parser[0].account_id : var.existing_boot_volume_kms_key_crn != null ? module.existing_boot_volume_kms_key_crn_parser[0].account_id : null
  boot_volume_kms_key_id        = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_boot_volume ? module.kms[0].keys[format("%s.%s", local.boot_volume_key_ring_name, local.boot_volume_key_name)].key_id : var.existing_boot_volume_kms_key_crn != null ? module.existing_boot_volume_kms_key_crn_parser[0].resource : null

  kms_config = var.kms_encryption_enabled_cluster ? {
    crk_id           = local.cluster_kms_key_id
    instance_id      = local.cluster_existing_kms_guid
    private_endpoint = var.kms_endpoint_type == "private" ? true : false
    account_id       = local.cluster_kms_account_id
  } : null
}

locals {
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
          force_delete             = true
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
          force_delete             = true
        }
      ]
    } : null
  ]
}


# KMS root key for cluster or boot volume
module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = (var.kms_encryption_enabled_boot_volume && var.existing_boot_volume_kms_key_crn == null) || (var.kms_encryption_enabled_cluster && var.existing_cluster_kms_key_crn == null) ? 1 : 0
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "5.1.7"
  create_key_protect_instance = false
  region                      = local.cluster_kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys                        = [for key in local.keys : key if key != null]
}

########################################################################################################################
# OCP VPC cluster
########################################################################################################################
module "existing_vpc_crn_parser" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_vpc_crn
}

locals {
  vpc_region      = module.existing_vpc_crn_parser.region
  existing_vpc_id = module.existing_vpc_crn_parser.resource
}

data "ibm_is_subnets" "vpc_subnets" {
  vpc = local.existing_vpc_id
}

data "ibm_is_subnet" "subnets" {
  count      = length(var.existing_subnet_ids) > 0 ? length(var.existing_subnet_ids) : 0
  identifier = var.existing_subnet_ids[count.index]
}

locals {
  vpc_subnets = {
    # The default behavior is to deploy the worker pool across all subnets within the VPC.
    "default" = length(var.existing_subnet_ids) > 0 ? [
      for i in range(length(var.existing_subnet_ids)) :
      {
        id         = data.ibm_is_subnet.subnets[i].id
        zone       = data.ibm_is_subnet.subnets[i].zone
        cidr_block = data.ibm_is_subnet.subnets[i].ipv4_cidr_block
      }
      ] : [
      for subnet in data.ibm_is_subnets.vpc_subnets.subnets :
      {
        id         = subnet.id
        zone       = subnet.zone
        cidr_block = subnet.ipv4_cidr_block
      }
    ]
  }

  worker_pools = concat([
    {
      subnet_prefix     = "default"
      pool_name         = "default"
      machine_type      = var.default_worker_pool_machine_type
      workers_per_zone  = var.default_worker_pool_workers_per_zone
      resource_group_id = module.resource_group.resource_group_id
      operating_system  = var.default_worker_pool_operating_system
      labels            = var.default_worker_pool_labels
      minSize           = var.default_pool_minimum_number_of_nodes
      maxSize           = var.default_pool_maximum_number_of_nodes
      enableAutoscaling = var.enable_autoscaling_for_default_pool
      boot_volume_encryption_kms_config = {
        crk             = local.boot_volume_kms_key_id
        kms_instance_id = local.boot_volume_existing_kms_guid
        kms_account_id  = local.boot_volume_kms_account_id
      }
      additional_security_group_ids = var.additional_security_group_ids
    }
    ], [for pool in var.additional_worker_pools : merge(pool, { resource_group_id = module.resource_group.resource_group_id
      boot_volume_encryption_kms_config = {
        crk             = local.boot_volume_kms_key_id
        kms_instance_id = local.boot_volume_existing_kms_guid
        kms_account_id  = local.boot_volume_kms_account_id
    } }) if length(pool.vpc_subnets) > 0],
    [for pool in var.additional_worker_pools : {
      pool_name         = pool.pool_name
      machine_type      = pool.machine_type
      workers_per_zone  = pool.workers_per_zone
      resource_group_id = module.resource_group.resource_group_id
      operating_system  = pool.operating_system
      labels            = pool.labels
      minSize           = pool.minSize
      secondary_storage = pool.secondary_storage
      maxSize           = pool.maxSize
      enableAutoscaling = pool.enableAutoscaling
      boot_volume_encryption_kms_config = {
        crk             = local.boot_volume_kms_key_id
        kms_instance_id = local.boot_volume_existing_kms_guid
        kms_account_id  = local.boot_volume_kms_account_id
      }
      additional_security_group_ids = pool.additional_security_group_ids
      subnet_prefix                 = "default"
  } if length(pool.vpc_subnets) == 0])
}

module "ocp_base" {
  source                                   = "../.."
  resource_group_id                        = module.resource_group.resource_group_id
  region                                   = local.vpc_region
  tags                                     = var.cluster_resource_tags
  cluster_name                             = local.cluster_name
  force_delete_storage                     = true
  use_existing_cos                         = true
  existing_cos_id                          = var.existing_cos_instance_crn
  vpc_id                                   = local.existing_vpc_id
  vpc_subnets                              = local.vpc_subnets
  ocp_version                              = var.ocp_version
  worker_pools                             = local.worker_pools
  access_tags                              = var.access_tags
  ocp_entitlement                          = var.ocp_entitlement
  additional_lb_security_group_ids         = var.additional_lb_security_group_ids
  additional_vpe_security_group_ids        = var.additional_vpe_security_group_ids
  addons                                   = var.addons
  allow_default_worker_pool_replacement    = var.allow_default_worker_pool_replacement
  attach_ibm_managed_security_group        = var.attach_ibm_managed_security_group
  cluster_config_endpoint_type             = var.cluster_config_endpoint_type
  cbr_rules                                = var.cbr_rules
  cluster_ready_when                       = var.cluster_ready_when
  custom_security_group_ids                = var.custom_security_group_ids
  disable_outbound_traffic_protection      = var.disable_outbound_traffic_protection
  disable_public_endpoint                  = var.disable_public_endpoint
  enable_ocp_console                       = var.enable_ocp_console
  ignore_worker_pool_size_changes          = var.ignore_worker_pool_size_changes
  kms_config                               = local.kms_config
  manage_all_addons                        = var.manage_all_addons
  number_of_lbs                            = var.number_of_lbs
  pod_subnet_cidr                          = var.pod_subnet_cidr
  service_subnet_cidr                      = var.service_subnet_cidr
  use_private_endpoint                     = var.use_private_endpoint
  verify_worker_network_readiness          = var.verify_worker_network_readiness
  worker_pools_taints                      = var.worker_pools_taints
  enable_secrets_manager_integration       = var.enable_secrets_manager_integration
  existing_secrets_manager_instance_crn    = var.existing_secrets_manager_instance_crn
  secrets_manager_secret_group_id          = var.secrets_manager_secret_group_id != null ? var.secrets_manager_secret_group_id : (var.enable_secrets_manager_integration ? module.secret_group[0].secret_group_id : null)
  skip_ocp_secrets_manager_iam_auth_policy = var.skip_ocp_secrets_manager_iam_auth_policy
}

module "existing_secrets_manager_instance_parser" {
  count   = var.enable_secrets_manager_integration ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_secrets_manager_instance_crn
}

resource "terraform_data" "delete_secrets" {

  count = var.enable_secrets_manager_integration && var.secrets_manager_secret_group_id == null ? 1 : 0
  input = {
    secret_id                   = module.secret_group[0].secret_group_id
    api_key                     = var.ibmcloud_api_key
    provider_visibility         = var.provider_visibility
    secrets_manager_instance_id = module.existing_secrets_manager_instance_parser[0].service_instance
    secrets_manager_region      = module.existing_secrets_manager_instance_parser[0].region
    secrets_manager_endpoint    = var.secrets_manager_endpoint_type
  }
  provisioner "local-exec" {
    when        = destroy
    command     = "${path.module}/scripts/delete_secrets.sh ${self.input.secret_id} ${self.input.provider_visibility} ${self.input.secrets_manager_instance_id} ${self.input.secrets_manager_region} ${self.input.secrets_manager_endpoint}"
    interpreter = ["/bin/bash", "-c"]

    environment = {
      API_KEY = self.input.api_key
    }
  }
}

module "secret_group" {
  providers = {
    ibm = ibm.secrets_manager
  }
  count                    = var.enable_secrets_manager_integration && var.secrets_manager_secret_group_id == null ? 1 : 0
  source                   = "terraform-ibm-modules/secrets-manager-secret-group/ibm"
  version                  = "1.3.7"
  region                   = module.existing_secrets_manager_instance_parser[0].region
  secrets_manager_guid     = module.existing_secrets_manager_instance_parser[0].service_instance
  secret_group_name        = module.ocp_base.cluster_id
  secret_group_description = "Secret group for storing ingress certificates for cluster ${var.cluster_name} with id: ${module.ocp_base.cluster_id}"
  endpoint_type            = var.secrets_manager_endpoint_type
}
