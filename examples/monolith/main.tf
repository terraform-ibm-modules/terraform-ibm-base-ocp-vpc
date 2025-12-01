########################################################################################################################
# Resource group
########################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.0"
  existing_resource_group_name = var.existing_resource_group_name
}

########################################################################################################################
# Add-ons
########################################################################################################################

module "monolith_add_ons" {
  source                                    = "../../modules/monolith"
  prefix                                    = var.prefix
  region                                    = var.region
  resource_group_id                         = module.resource_group.resource_group_id
  kms_encryption_enabled_cluster            = var.kms_encryption_enabled_cluster
  existing_kms_instance_crn                 = var.existing_kms_instance_crn
  existing_cluster_kms_key_crn              = var.existing_cluster_kms_key_crn
  kms_endpoint_type                         = var.kms_endpoint_type
  key_protect_allowed_network               = var.key_protect_allowed_network
  kms_encryption_enabled_boot_volume        = var.kms_encryption_enabled_boot_volume
  existing_boot_volume_kms_key_crn          = var.existing_boot_volume_kms_key_crn
  kms_plan                                  = var.kms_plan
  existing_secrets_manager_crn              = var.existing_secrets_manager_crn
  secrets_manager_service_plan              = var.secrets_manager_service_plan
  secrets_manager_endpoint_type             = var.secrets_manager_endpoint_type
  secrets_manager_allowed_network           = var.secrets_manager_allowed_network
  existing_event_notifications_instance_crn = var.existing_event_notifications_instance_crn
  existing_cos_instance_crn                 = var.existing_cos_instance_crn
  cos_instance_plan                         = var.cos_instance_plan
  existing_cloud_monitoring_crn             = var.existing_cloud_monitoring_crn
  cloud_monitoring_plan                     = var.cloud_monitoring_plan
  existing_cloud_logs_crn                   = var.existing_cloud_logs_crn
  scc_workload_protection_service_plan      = var.scc_workload_protection_service_plan
  enable_vpc_flow_logs                      = var.enable_vpc_flow_logs
}

########################################################################################################################
# OCP VPC cluster
########################################################################################################################

locals {
  vpc_subnets = {
    # The default behavior is to deploy the worker pool across all subnets within the VPC.
    "default" = [
      for subnet in module.monolith_add_ons.subnet_zone_list :
      {
        id         = subnet.id
        zone       = subnet.zone
        cidr_block = subnet.cidr
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
        crk             = module.monolith_add_ons.boot_volume_kms_key_id
        kms_instance_id = module.monolith_add_ons.boot_volume_existing_kms_guid
        kms_account_id  = module.monolith_add_ons.boot_volume_kms_account_id
      }
      additional_security_group_ids = var.additional_security_group_ids
    }
    ], [for pool in var.additional_worker_pools : merge(pool, { resource_group_id = module.resource_group.resource_group_id
      boot_volume_encryption_kms_config = {
        crk             = module.monolith_add_ons.boot_volume_kms_key_id
        kms_instance_id = module.monolith_add_ons.boot_volume_existing_kms_guid
        kms_account_id  = module.monolith_add_ons.boot_volume_kms_account_id
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
        crk             = module.monolith_add_ons.boot_volume_kms_key_id
        kms_instance_id = module.monolith_add_ons.boot_volume_existing_kms_guid
        kms_account_id  = module.monolith_add_ons.boot_volume_kms_account_id
      }
      additional_security_group_ids = pool.additional_security_group_ids
      subnet_prefix                 = "default"
  } if length(pool.vpc_subnets) == 0])

  # Managing the ODF version accordingly, as it changes with each OCP version.
  addons = lookup(var.addons, "openshift-data-foundation", null) != null ? lookup(var.addons["openshift-data-foundation"], "version", null) == null ? { for key, value in var.addons :
    key => value != null ? {
      version         = lookup(value, "version", null) == null && key == "openshift-data-foundation" ? "${var.openshift_version}.0" : lookup(value, "version", null)
      parameters_json = lookup(value, "parameters_json", null)
  } : null } : var.addons : var.addons
}

module "ocp_base" {
  depends_on                               = [module.monolith_add_ons]
  source                                   = "../.."
  resource_group_id                        = module.resource_group.resource_group_id
  region                                   = var.region
  tags                                     = var.cluster_resource_tags
  cluster_name                             = "${var.prefix}-${var.cluster_name}"
  force_delete_storage                     = true
  use_existing_cos                         = true
  existing_cos_id                          = module.monolith_add_ons.cos_instance_id
  vpc_id                                   = module.monolith_add_ons.vpc_id
  vpc_subnets                              = local.vpc_subnets
  ocp_version                              = var.openshift_version
  worker_pools                             = local.worker_pools
  access_tags                              = var.access_tags
  ocp_entitlement                          = var.ocp_entitlement
  additional_lb_security_group_ids         = var.additional_lb_security_group_ids
  additional_vpe_security_group_ids        = var.additional_vpe_security_group_ids
  addons                                   = local.addons
  allow_default_worker_pool_replacement    = var.allow_default_worker_pool_replacement
  attach_ibm_managed_security_group        = var.attach_ibm_managed_security_group
  cluster_config_endpoint_type             = var.cluster_config_endpoint_type
  cbr_rules                                = var.ocp_cbr_rules
  cluster_ready_when                       = var.cluster_ready_when
  custom_security_group_ids                = var.custom_security_group_ids
  disable_outbound_traffic_protection      = var.allow_outbound_traffic
  disable_public_endpoint                  = !var.allow_public_access_to_cluster_management
  enable_ocp_console                       = var.enable_ocp_console
  ignore_worker_pool_size_changes          = var.ignore_worker_pool_size_changes
  kms_config                               = module.monolith_add_ons.kms_config
  manage_all_addons                        = var.manage_all_addons
  number_of_lbs                            = var.number_of_lbs
  pod_subnet_cidr                          = var.pod_subnet_cidr
  service_subnet_cidr                      = var.service_subnet_cidr
  verify_worker_network_readiness          = var.verify_worker_network_readiness
  worker_pools_taints                      = var.worker_pools_taints
  enable_secrets_manager_integration       = var.enable_secrets_manager_integration
  existing_secrets_manager_instance_crn    = module.monolith_add_ons.secrets_manager_crn
  secrets_manager_secret_group_id          = var.secrets_manager_secret_group_id != null ? var.secrets_manager_secret_group_id : (var.enable_secrets_manager_integration ? module.secret_group[0].secret_group_id : null)
  skip_ocp_secrets_manager_iam_auth_policy = var.skip_ocp_secrets_manager_iam_auth_policy
}

resource "terraform_data" "delete_secrets" {
  depends_on = [module.monolith_add_ons]
  count      = var.enable_secrets_manager_integration && var.secrets_manager_secret_group_id == null ? 1 : 0
  input = {
    secret_id                   = module.secret_group[0].secret_group_id
    provider_visibility         = var.provider_visibility
    secrets_manager_instance_id = module.monolith_add_ons.secrets_manager_guid
    secrets_manager_region      = module.monolith_add_ons.secrets_manager_region
    secrets_manager_endpoint    = var.secrets_manager_endpoint_type
  }
  # api key in triggers_replace to avoid it to be printed out in clear text in terraform_data output
  triggers_replace = {
    api_key = var.ibmcloud_api_key
  }
  provisioner "local-exec" {
    when        = destroy
    command     = "${path.module}/../../solutions/fully-configurable/scripts/delete_secrets.sh ${self.input.secret_id} ${self.input.provider_visibility} ${self.input.secrets_manager_instance_id} ${self.input.secrets_manager_region} ${self.input.secrets_manager_endpoint}"
    interpreter = ["/bin/bash", "-c"]

    environment = {
      API_KEY = self.triggers_replace.api_key
    }
  }
}

module "secret_group" {
  count                    = var.enable_secrets_manager_integration && var.secrets_manager_secret_group_id == null ? 1 : 0
  source                   = "terraform-ibm-modules/secrets-manager-secret-group/ibm"
  version                  = "1.3.15"
  region                   = module.monolith_add_ons.secrets_manager_region
  secrets_manager_guid     = module.monolith_add_ons.secrets_manager_guid
  secret_group_name        = module.ocp_base.cluster_id
  secret_group_description = "Secret group for storing ingress certificates for cluster ${var.cluster_name} with id: ${module.ocp_base.cluster_id}"
  endpoint_type            = var.secrets_manager_endpoint_type
}

data "ibm_container_cluster_config" "cluster_config" {
  count             = var.enable_kube_audit ? 1 : 0
  cluster_name_id   = module.ocp_base.cluster_id
  config_dir        = "${path.module}/../../kubeconfig"
  admin             = true
  resource_group_id = module.ocp_base.resource_group_id
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null
}

module "kube_audit" {
  count                                   = var.enable_kube_audit ? 1 : 0
  ibmcloud_api_key                        = var.ibmcloud_api_key
  source                                  = "../../modules/kube-audit"
  cluster_id                              = module.ocp_base.cluster_id
  cluster_resource_group_id               = module.ocp_base.resource_group_id
  region                                  = module.ocp_base.region
  use_private_endpoint                    = var.use_private_endpoint
  cluster_config_endpoint_type            = var.cluster_config_endpoint_type
  audit_log_policy                        = var.audit_log_policy
  audit_namespace                         = var.audit_namespace
  audit_deployment_name                   = var.audit_deployment_name
  audit_webhook_listener_image            = var.audit_webhook_listener_image
  audit_webhook_listener_image_tag_digest = var.audit_webhook_listener_image_tag_digest
}
