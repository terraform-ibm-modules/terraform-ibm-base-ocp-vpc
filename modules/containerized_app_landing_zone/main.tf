#################################################################################
# KMS
#################################################################################

module "existing_kms_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_kms_instance_crn
}

module "existing_cluster_kms_key_crn_parser" {
  count   = var.existing_cluster_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_cluster_kms_key_crn
}

module "existing_boot_volume_kms_key_crn_parser" {
  count   = var.existing_boot_volume_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_boot_volume_kms_key_crn
}

locals {
  prefix                    = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  cluster_existing_kms_guid = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_cluster ? module.existing_kms_crn_parser[0].service_instance : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].service_instance : var.kms_encryption_enabled_cluster ? module.kms[0].kms_guid : null
  cluster_kms_account_id    = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_cluster ? module.existing_kms_crn_parser[0].account_id : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].account_id : var.kms_encryption_enabled_cluster ? module.kms[0].kms_account_id : null
  cluster_kms_key_id        = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_cluster ? module.kms[0].keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].key_id : var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].resource : var.kms_encryption_enabled_cluster ? module.kms[0].keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].key_id : null
  cluster_kms_key_crn       = var.kms_encryption_enabled_cluster ? module.kms[0].keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].crn : var.existing_cluster_kms_key_crn != null ? var.existing_boot_volume_kms_key_crn : var.kms_encryption_enabled_cluster ? module.kms[0].key_protect_crn : null
  cluster_key_ring_name     = "${local.prefix}${var.cluster_kms_key_ring_name}"
  cluster_key_name          = "${local.prefix}${var.cluster_kms_key_name}"
  cluster_name              = "${local.prefix}${var.cluster_name}"

  boot_volume_key_ring_name     = "${local.prefix}${var.boot_volume_kms_key_ring_name}"
  boot_volume_key_name          = "${local.prefix}${var.boot_volume_kms_key_name}"
  boot_volume_existing_kms_guid = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_boot_volume ? module.existing_kms_crn_parser[0].service_instance : var.existing_boot_volume_kms_key_crn != null ? module.existing_boot_volume_kms_key_crn_parser[0].service_instance : var.kms_encryption_enabled_cluster ? module.kms[0].kms_guid : null
  boot_volume_kms_account_id    = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_boot_volume ? module.existing_kms_crn_parser[0].account_id : var.existing_boot_volume_kms_key_crn != null ? module.existing_boot_volume_kms_key_crn_parser[0].account_id : var.kms_encryption_enabled_cluster ? module.kms[0].kms_account_id : null
  boot_volume_kms_key_id        = var.existing_kms_instance_crn != null && var.kms_encryption_enabled_boot_volume ? module.kms[0].keys[format("%s.%s", local.boot_volume_key_ring_name, local.boot_volume_key_name)].key_id : var.existing_boot_volume_kms_key_crn != null ? module.existing_boot_volume_kms_key_crn_parser[0].resource : var.kms_encryption_enabled_boot_volume ? module.kms[0].keys[format("%s.%s", local.boot_volume_key_ring_name, local.boot_volume_key_name)].key_id : null
  parsed_service_name           = var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].service_name : (var.existing_cluster_kms_key_crn != null ? module.existing_cluster_kms_key_crn_parser[0].service_name : null)
  is_hpcs_key                   = local.parsed_service_name == "hs-crypto" ? true : false

  kms_config = var.kms_encryption_enabled_cluster ? {
    crk_id           = local.cluster_kms_key_id
    instance_id      = local.cluster_existing_kms_guid
    private_endpoint = var.kms_endpoint_type == "private" ? true : false
    account_id       = local.cluster_kms_account_id
  } : null

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

module "kms" {
  count                            = (var.kms_encryption_enabled_boot_volume && var.existing_boot_volume_kms_key_crn == null) || (var.kms_encryption_enabled_cluster && var.existing_cluster_kms_key_crn == null) ? 1 : 0
  source                           = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                          = "5.4.5"
  resource_group_id                = var.resource_group_id
  region                           = var.region
  create_key_protect_instance      = var.existing_kms_instance_crn != null || var.existing_cluster_kms_key_crn != null || var.existing_boot_volume_kms_key_crn != null ? false : true
  existing_kms_instance_crn        = var.existing_kms_instance_crn
  key_protect_instance_name        = "${local.prefix}${var.kms_instance_name}"
  key_protect_plan                 = var.kms_plan
  rotation_enabled                 = var.rotation_enabled
  rotation_interval_month          = var.rotation_interval_month
  dual_auth_delete_enabled         = var.dual_auth_delete_enabled
  enable_metrics                   = var.enable_metrics
  key_create_import_access_enabled = var.key_create_import_access_enabled
  key_protect_allowed_network      = var.key_protect_allowed_network
  key_ring_endpoint_type           = var.kms_endpoint_type
  key_endpoint_type                = var.kms_endpoint_type
  resource_tags                    = var.kms_resource_tags
  access_tags                      = var.kms_access_tags
  keys                             = [for key in local.keys : key if key != null]
  cbr_rules                        = var.kms_cbr_rules
}

#################################################################################
# Cloud Monitoring
#################################################################################

module "existing_cloud_monitoring_crn_parser" {
  count   = var.existing_cloud_monitoring_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_cloud_monitoring_crn
}

locals {
  create_cloud_monitoring        = var.existing_cloud_monitoring_crn == null
  cloud_monitoring_crn           = local.create_cloud_monitoring ? module.cloud_monitoring[0].crn : var.existing_cloud_monitoring_crn
  cloud_monitoring_instance_name = "${local.prefix}${var.cloud_monitoring_instance_name}"
  metrics_router_target_name     = "${local.prefix}${var.metrics_routing_target_name}"
  metrics_router_route_name      = "${local.prefix}${var.metrics_routing_route_name}"

  default_metrics_router_route = var.enable_metrics_routing_to_cloud_monitoring ? [{
    name = local.metrics_router_route_name
    rules = [{
      action = "send"
      targets = [{
        id = module.metrics_routing[0].metrics_router_targets[local.metrics_router_target_name].id
      }]
      inclusion_filters = []
    }]
  }] : []
}

module "cloud_monitoring" {
  count                       = local.create_cloud_monitoring ? 1 : 0
  source                      = "terraform-ibm-modules/cloud-monitoring/ibm"
  version                     = "1.11.0"
  resource_group_id           = var.resource_group_id
  region                      = var.region
  instance_name               = local.cloud_monitoring_instance_name
  plan                        = var.cloud_monitoring_plan
  resource_tags               = var.cloud_monitoring_resource_tags
  access_tags                 = var.cloud_monitoring_access_tags
  resource_keys               = var.cloud_monitoring_resource_keys
  disable_access_key_creation = var.disable_access_key_creation
  service_endpoints           = "public-and-private"
  enable_platform_metrics     = var.enable_platform_metrics
  cbr_rules                   = var.cloud_monitoring_cbr_rules
}

module "metrics_routing" {
  count   = var.enable_metrics_routing_to_cloud_monitoring ? 1 : 0
  source  = "terraform-ibm-modules/cloud-monitoring/ibm//modules/metrics_routing"
  version = "1.11.0"
  metrics_router_targets = [
    {
      destination_crn                 = local.cloud_monitoring_crn
      target_name                     = local.metrics_router_target_name
      target_region                   = var.region
      skip_metrics_router_auth_policy = false
    }
  ]

  metrics_router_routes   = length(var.metrics_router_routes) != 0 ? var.metrics_router_routes : local.default_metrics_router_route
  metrics_router_settings = var.enable_primary_metadata_region ? { primary_metadata_region = var.region } : null
}



########################################################################################################################
# Event Notifications
########################################################################################################################

# If existing EN instance CRN passed, parse details from it
module "existing_en_crn_parser" {
  count   = var.existing_event_notifications_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_event_notifications_instance_crn
}

locals {
  use_existing_en_instance  = var.existing_event_notifications_instance_crn != null
  existing_en_instance_guid = local.use_existing_en_instance ? module.existing_en_crn_parser[0].service_instance : null
  eventnotification_guid    = local.use_existing_en_instance ? local.existing_en_instance_guid : module.event_notifications[0].guid
  eventnotification_crn     = local.use_existing_en_instance ? var.existing_event_notifications_instance_crn : module.event_notifications[0].crn
  en_cos_bucket_name        = "${local.prefix}${var.en_cos_bucket_name}"
}

module "event_notifications" {
  count                    = local.use_existing_en_instance ? 0 : 1
  source                   = "terraform-ibm-modules/event-notifications/ibm"
  version                  = "2.7.0"
  resource_group_id        = var.resource_group_id
  region                   = var.region
  name                     = "${local.prefix}${var.event_notifications_instance_name}"
  plan                     = var.en_service_plan
  tags                     = var.en_resource_tags
  access_tags              = var.en_access_tags
  service_endpoints        = var.en_service_endpoints
  service_credential_names = var.en_service_credential_names
  # KMS Related
  kms_encryption_enabled    = var.kms_encryption_enabled_cluster
  kms_endpoint_url          = (var.kms_encryption_enabled_boot_volume && var.existing_boot_volume_kms_key_crn == null) || (var.kms_encryption_enabled_cluster && var.existing_cluster_kms_key_crn == null) ? var.kms_endpoint_type == "private" ? module.kms[0].kms_private_endpoint : module.kms[0].kms_public_endpoint : var.kms_endpoint_url
  existing_kms_instance_crn = var.existing_kms_instance_crn != null ? var.existing_kms_instance_crn : module.kms[0].key_protect_crn
  root_key_id               = local.cluster_kms_key_id
  skip_en_kms_auth_policy   = var.skip_event_notifications_kms_auth_policy
  # COS Related
  cos_integration_enabled = var.enable_collecting_failed_events
  cos_bucket_name         = var.existing_event_notifications_instance_crn == null && var.enable_collecting_failed_events ? module.en_cos_buckets[0].buckets[local.en_cos_bucket_name].bucket_name : null
  cos_instance_id         = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].resource : module.cos[0].cos_instance_id
  skip_en_cos_auth_policy = var.skip_event_notifications_cos_auth_policy
  cos_endpoint            = var.existing_event_notifications_instance_crn == null && var.enable_collecting_failed_events ? "https://${module.en_cos_buckets[0].buckets[local.en_cos_bucket_name].s3_endpoint_direct}" : null
  cbr_rules               = var.en_cbr_rules
}

locals {
  bucket_config = [{
    access_tags                   = var.en_cos_bucket_access_tags
    bucket_name                   = local.en_cos_bucket_name
    add_bucket_name_suffix        = var.append_random_bucket_name_suffix
    kms_encryption_enabled        = var.kms_encryption_enabled_buckets
    kms_guid                      = local.cluster_existing_kms_guid
    kms_key_crn                   = local.cluster_kms_key_crn
    skip_iam_authorization_policy = false
    management_endpoint_type      = var.management_endpoint_type_for_buckets
    storage_class                 = var.cos_buckets_class
    resource_instance_id          = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].resource : module.cos[0].cos_instance_id
    region_location               = var.region
    activity_tracking = {
      read_data_events  = true
      write_data_events = true
      management_events = true
    }
    metrics_monitoring = {
      usage_metrics_enabled   = true
      request_metrics_enabled = true
      metrics_monitoring_crn  = var.existing_cloud_monitoring_crn != null ? var.existing_cloud_monitoring_crn : module.cloud_monitoring[0].crn
    }
    force_delete = true
  }]
}

module "en_cos_buckets" {
  count          = var.enable_collecting_failed_events && var.existing_event_notifications_instance_crn == null ? 1 : 0
  source         = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version        = "10.5.8"
  bucket_configs = local.bucket_config
}

########################################################################################################################
# Service Credentials
########################################################################################################################

# If existing EN instance CRN passed, parse details from it
module "existing_sm_crn_parser" {
  count   = var.existing_secrets_manager_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_secrets_manager_crn
}

locals {
  en_service_credential_secrets = [
    for service_credentials in var.en_service_credential_secrets : {
      secret_group_name        = service_credentials.secret_group_name
      secret_group_description = service_credentials.secret_group_description
      existing_secret_group    = service_credentials.existing_secret_group
      secrets = [
        for secret in service_credentials.service_credentials : {
          secret_name                                 = secret.secret_name
          secret_labels                               = secret.secret_labels
          secret_auto_rotation                        = secret.secret_auto_rotation
          secret_auto_rotation_unit                   = secret.secret_auto_rotation_unit
          secret_auto_rotation_interval               = secret.secret_auto_rotation_interval
          service_credentials_ttl                     = secret.service_credentials_ttl
          service_credential_secret_description       = secret.service_credential_secret_description
          service_credentials_source_service_role_crn = secret.service_credentials_source_service_role_crn
          service_credentials_source_service_crn      = local.eventnotification_crn
          secret_type                                 = "service_credentials" #checkov:skip=CKV_SECRET_6
        }
      ]
    }
  ]
}

# create a service authorization between Secrets Manager and the target service (Event Notification)
resource "ibm_iam_authorization_policy" "en_secrets_manager_key_manager" {
  count                       = var.skip_event_notifications_secrets_manager_auth_policy || var.existing_secrets_manager_crn == null ? 0 : 1
  source_service_name         = "secrets-manager"
  source_resource_instance_id = local.existing_secrets_manager_instance_guid
  target_service_name         = "event-notifications"
  target_resource_instance_id = local.eventnotification_guid
  roles                       = ["Key Manager"]
  description                 = "Allow Secrets Manager instance to manage key for the event-notification instance"
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_en_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.en_secrets_manager_key_manager]
  create_duration = "30s"
}

module "en_secrets_manager_service_credentials" {
  count                       = length(local.en_service_credential_secrets) > 0 ? 1 : 0
  depends_on                  = [time_sleep.wait_for_en_authorization_policy]
  source                      = "terraform-ibm-modules/secrets-manager/ibm//modules/secrets"
  version                     = "2.11.9"
  existing_sm_instance_guid   = local.existing_secrets_manager_instance_guid
  existing_sm_instance_region = local.existing_secrets_manager_instance_region
  endpoint_type               = var.secrets_manager_endpoint_type
  secrets                     = local.en_service_credential_secrets
}

#################################################################################
# Secrets Manager
#################################################################################

locals {
  enable_secrets_manager_cluster      = var.existing_secrets_manager_crn == null ? true : false
  parsed_existing_secrets_manager_crn = var.existing_secrets_manager_crn != null ? split(":", var.existing_secrets_manager_crn) : []
  secrets_manager_guid                = var.existing_secrets_manager_crn != null ? (length(local.parsed_existing_secrets_manager_crn) > 0 ? local.parsed_existing_secrets_manager_crn[7] : null) : module.secrets_manager[0].secrets_manager_guid
  secrets_manager_crn                 = var.existing_secrets_manager_crn != null ? var.existing_secrets_manager_crn : module.secrets_manager[0].secrets_manager_crn
  secrets_manager_region              = var.existing_secrets_manager_crn != null ? (length(local.parsed_existing_secrets_manager_crn) > 0 ? local.parsed_existing_secrets_manager_crn[5] : null) : module.secrets_manager[0].secrets_manager_region
  secret_groups_with_prefix = [
    for group in var.secret_groups : merge(group, {
      access_group_name = group.access_group_name != null ? "${local.prefix}${group.access_group_name}" : null
    })
  ]
}

module "secrets_manager_crn_parser" {
  count   = var.existing_secrets_manager_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_secrets_manager_crn
}

module "secrets_manager" {
  count                         = local.enable_secrets_manager_cluster ? 1 : 0
  source                        = "terraform-ibm-modules/secrets-manager/ibm"
  version                       = "2.11.9"
  existing_sm_instance_crn      = var.existing_secrets_manager_crn
  resource_group_id             = var.resource_group_id
  region                        = var.region
  secrets_manager_name          = "${local.prefix}${var.secrets_manager_instance_name}"
  sm_service_plan               = var.secrets_manager_service_plan
  sm_tags                       = var.secrets_manager_resource_tags
  skip_iam_authorization_policy = var.skip_secrets_manager_iam_auth_policy
  # kms dependency
  is_hpcs_key                       = local.is_hpcs_key
  kms_encryption_enabled            = var.kms_encryption_enabled_cluster
  kms_key_crn                       = local.cluster_kms_key_crn
  skip_kms_iam_authorization_policy = var.skip_secrets_manager_kms_iam_auth_policy #|| local.create_cross_account_auth_policy
  # event notifications dependency
  enable_event_notification        = true
  existing_en_instance_crn         = local.eventnotification_crn
  skip_en_iam_authorization_policy = var.skip_secrets_manager_event_notifications_iam_auth_policy
  cbr_rules                        = var.secrets_manager_cbr_rules
  endpoint_type                    = var.secrets_manager_endpoint_type
  allowed_network                  = var.secrets_manager_allowed_network
  secrets                          = local.secret_groups_with_prefix
}

#################################################################################
# Secrets Manager Event Notifications Configuration
#################################################################################

locals {
  parsed_existing_en_instance_crn = split(":", local.eventnotification_crn)
  existing_en_guid                = length(local.parsed_existing_en_instance_crn) > 0 ? local.parsed_existing_en_instance_crn[7] : null
}

data "ibm_en_destinations" "en_sm_destinations" {
  # if existing SM instance CRN is passed (!= null), then never do data lookup for EN destinations
  count         = var.existing_secrets_manager_crn == null && local.enable_secrets_manager_cluster ? 1 : 0
  instance_guid = local.existing_en_guid
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/5533
resource "time_sleep" "wait_for_secrets_manager" {
  # if existing SM instance CRN is passed (!= null), then never work with EN
  count      = var.existing_secrets_manager_crn == null && local.enable_secrets_manager_cluster ? 1 : 0
  depends_on = [module.secrets_manager]

  create_duration = "30s"
}

resource "ibm_en_topic" "en_sm_topic" {
  # if existing SM instance CRN is passed (!= null), then never create EN topic
  count         = var.existing_secrets_manager_crn == null && local.enable_secrets_manager_cluster ? 1 : 0
  depends_on    = [time_sleep.wait_for_secrets_manager]
  instance_guid = local.existing_en_guid
  name          = "Topic for Secrets Manager instance ${module.secrets_manager[0].secrets_manager_guid}"
  description   = "Topic for Secrets Manager events routing"
  sources {
    id = local.secrets_manager_crn
    rules {
      enabled           = true
      event_type_filter = "$.*"
    }
  }
}

resource "ibm_en_subscription_email" "en_email_subscription" {
  # if existing SM instance CRN is passed (!= null), then never create EN email subscription
  count          = var.existing_secrets_manager_crn == null && length(var.event_notifications_email_list) > 0 && local.enable_secrets_manager_cluster ? 1 : 0
  instance_guid  = local.existing_en_guid
  name           = "Email for Secrets Manager Subscription"
  description    = "Subscription for Secret Manager Events"
  destination_id = [for s in toset(data.ibm_en_destinations.en_sm_destinations[count.index].destinations) : s.id if s.type == "smtp_ibm"][0]
  topic_id       = ibm_en_topic.en_sm_topic[count.index].topic_id
  attributes {
    add_notification_payload = true
    reply_to_mail            = var.event_notifications_reply_to_email
    reply_to_name            = "Secret Manager Event Notifications Bot"
    from_name                = var.event_notifications_from_email
    invited                  = var.event_notifications_email_list
  }
}

#################################################################################
# COS
#################################################################################

locals {
  create_cos_instance                      = var.existing_cos_instance_crn == null ? true : false
  existing_secrets_manager_instance_guid   = var.existing_secrets_manager_crn != null ? module.secrets_manager_crn_parser[0].service_instance : local.enable_secrets_manager_cluster ? module.secrets_manager[0].secrets_manager_guid : ""
  existing_secrets_manager_instance_region = var.existing_secrets_manager_crn != null ? module.secrets_manager_crn_parser[0].region : local.enable_secrets_manager_cluster ? module.secrets_manager[0].secrets_manager_region : ""

  cos_service_credential_secrets = [
    for service_credentials in var.service_cred : {
      secret_group_name        = service_credentials.secret_group_name
      secret_group_description = service_credentials.secret_group_description
      existing_secret_group    = service_credentials.existing_secret_group
      secrets = [
        for secret in service_credentials.service_credentials : {
          secret_name                                 = secret.secret_name
          secret_labels                               = secret.secret_labels
          secret_auto_rotation                        = secret.secret_auto_rotation
          secret_auto_rotation_unit                   = secret.secret_auto_rotation_unit
          secret_auto_rotation_interval               = secret.secret_auto_rotation_interval
          service_credentials_ttl                     = secret.service_credentials_ttl
          service_credential_secret_description       = secret.service_credential_secret_description
          service_credentials_source_service_role_crn = secret.service_credentials_source_service_role_crn
          service_credentials_source_service_crn      = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].service_instance : module.cos[0].cos_instance_id
          secret_type                                 = "service_credentials" #checkov:skip=CKV_SECRET_6
        }
      ]
    }
  ]
}

module "existing_cos_instance_crn_parser" {
  count   = var.existing_cos_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_cos_instance_crn
}

module "cos" {
  count               = local.create_cos_instance != false ? 1 : 0
  source              = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version             = "10.5.9"
  resource_group_id   = var.resource_group_id
  create_cos_instance = local.create_cos_instance
  cos_instance_name   = "${local.prefix}${var.cos_instance_name}"
  resource_keys       = []
  cos_plan            = var.cos_instance_plan
  cos_tags            = var.cos_instance_resource_tags
  access_tags         = var.cos_instance_access_tags
  instance_cbr_rules  = var.cos_instance_cbr_rules
}

#################################################################################
# Secrets Manager service credentials for COS
#################################################################################

# create s2s auth policy with Secrets Manager
resource "ibm_iam_authorization_policy" "cos_secrets_manager_key_manager" {
  count                       = !var.skip_secrets_manager_cos_iam_auth_policy && (var.existing_secrets_manager_crn != null || local.enable_secrets_manager_cluster) ? 1 : 0
  source_service_name         = "secrets-manager"
  source_resource_instance_id = local.existing_secrets_manager_instance_guid
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].service_instance : module.cos[0].cos_instance_guid
  roles                       = ["Key Manager"]
  description                 = "Allow Secrets Manager with instance id ${local.existing_secrets_manager_instance_guid} to manage key for the COS instance"
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_cos_authorization_policy" {
  count           = length(local.cos_service_credential_secrets) > 0 ? 1 : 0
  depends_on      = [ibm_iam_authorization_policy.cos_secrets_manager_key_manager]
  create_duration = "30s"
}

module "cos_secrets_manager_service_credentials" {
  count                       = length(local.cos_service_credential_secrets) > 0 ? 1 : 0
  depends_on                  = [time_sleep.wait_for_cos_authorization_policy]
  source                      = "terraform-ibm-modules/secrets-manager/ibm//modules/secrets"
  version                     = "2.11.9"
  existing_sm_instance_guid   = local.existing_secrets_manager_instance_guid
  existing_sm_instance_region = local.existing_secrets_manager_instance_region
  endpoint_type               = var.secrets_manager_endpoint_type
  secrets                     = local.cos_service_credential_secrets
}

#################################################################################
# Cloud Logs
#################################################################################

locals {
  cloud_logs_instance_name = "${local.prefix}${var.cloud_logs_instance_name}"
  create_cloud_logs        = var.existing_cloud_logs_crn == null
  cloud_logs_crn           = local.create_cloud_logs ? module.cloud_logs[0].crn : var.existing_cloud_logs_crn

  data_bucket_name    = "${local.prefix}${var.cloud_logs_data_cos_bucket_name}"
  metrics_bucket_name = "${local.prefix}${var.cloud_logs_metrics_cos_bucket_name}"
  cos_instance_guid   = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].service_instance : module.cos[0].cos_instance_guid
}

module "cloud_logs" {
  depends_on                             = [time_sleep.wait_for_cos_authorization_policy[0]]
  count                                  = local.create_cloud_logs ? 1 : 0
  source                                 = "terraform-ibm-modules/cloud-logs/ibm"
  version                                = "1.10.0"
  resource_group_id                      = var.resource_group_id
  region                                 = var.region
  instance_name                          = local.cloud_logs_instance_name
  plan                                   = "standard" # not a variable because there is only one option
  resource_tags                          = var.cloud_logs_resource_tags
  access_tags                            = var.cloud_logs_access_tags
  retention_period                       = var.cloud_logs_retention_period
  service_endpoints                      = "public-and-private" # not a variable because there is only one option
  existing_event_notifications_instances = var.existing_event_notifications_instances
  cbr_rules                              = var.cloud_logs_cbr_rules
  data_storage = {
    logs_data = {
      enabled              = true
      bucket_crn           = module.cloud_logs_buckets.buckets[local.data_bucket_name].bucket_crn
      bucket_endpoint      = module.cloud_logs_buckets.buckets[local.data_bucket_name].s3_endpoint_direct
      skip_cos_auth_policy = var.skip_cloud_logs_cos_auth_policy
    },
    metrics_data = {
      enabled              = true
      bucket_crn           = module.cloud_logs_buckets.buckets[local.metrics_bucket_name].bucket_crn
      bucket_endpoint      = module.cloud_logs_buckets.buckets[local.metrics_bucket_name].s3_endpoint_direct
      skip_cos_auth_policy = var.skip_cloud_logs_cos_auth_policy
    }
  }
  logs_routing_tenant_regions   = var.logs_routing_tenant_regions
  skip_logs_routing_auth_policy = var.skip_logs_routing_auth_policy
  policies                      = var.logs_policies
}

module "cloud_logs_buckets" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "10.5.8"
  bucket_configs = [
    {
      bucket_name              = local.data_bucket_name
      kms_key_crn              = var.kms_encryption_enabled_buckets ? local.cluster_kms_key_crn : null
      kms_guid                 = var.kms_encryption_enabled_buckets ? local.cluster_existing_kms_guid : null
      kms_encryption_enabled   = var.kms_encryption_enabled_buckets
      region_location          = var.region
      resource_instance_id     = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].resource : module.cos[0].cos_instance_id
      add_bucket_name_suffix   = var.append_random_bucket_name_suffix
      management_endpoint_type = var.management_endpoint_type_for_buckets
      storage_class            = var.cos_buckets_class
      force_delete             = true # If this is set to false, and the bucket contains data, the destroy will fail. Setting it to false on destroy has no impact, it has to be set on apply, so hence hard coding to true."
      activity_tracking = {
        read_data_events  = true
        write_data_events = true
        management_events = true
      }
      metrics_monitoring = {
        usage_metrics_enabled   = true
        request_metrics_enabled = true
        metrics_monitoring_crn  = var.existing_cloud_monitoring_crn != null ? var.existing_cloud_monitoring_crn : module.cloud_monitoring[0].crn
      }
    },
    {
      bucket_name                   = local.metrics_bucket_name
      kms_key_crn                   = var.kms_encryption_enabled_buckets ? local.cluster_kms_key_crn : null
      kms_guid                      = var.kms_encryption_enabled_buckets ? local.cluster_existing_kms_guid : null
      kms_encryption_enabled        = var.kms_encryption_enabled_buckets
      region_location               = var.region
      resource_instance_id          = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].resource : module.cos[0].cos_instance_id
      add_bucket_name_suffix        = var.append_random_bucket_name_suffix
      management_endpoint_type      = var.management_endpoint_type_for_buckets
      storage_class                 = var.cos_buckets_class
      skip_iam_authorization_policy = true
      force_delete                  = true # If this is set to false, and the bucket contains data, the destroy will fail. Setting it to false on destroy has no impact, it has to be set on apply, so hence hard coding to true."
      activity_tracking = {
        read_data_events  = true
        write_data_events = true
        management_events = true
      }
      metrics_monitoring = {
        usage_metrics_enabled   = true
        request_metrics_enabled = true
        metrics_monitoring_crn  = var.existing_cloud_monitoring_crn != null ? var.existing_cloud_monitoring_crn : module.cloud_monitoring[0].crn
      }
    }
  ]
}

#################################################################################
# Activity Tracker
#################################################################################
locals {
  activity_tracker_cos_target_bucket_name = try("${local.prefix}${var.activity_tracker_cos_target_bucket_name}", var.activity_tracker_cos_target_bucket_name)
  cos_target_bucket_name                  = var.existing_activity_tracker_cos_target_bucket_name != null ? var.existing_activity_tracker_cos_target_bucket_name : var.enable_activity_tracker_event_routing_to_cos_bucket ? module.at_cos_bucket[0].buckets[local.activity_tracker_cos_target_bucket_name].bucket_name : null
  cos_target_bucket_endpoint              = var.existing_activity_tracker_cos_target_bucket_endpoint != null ? var.existing_activity_tracker_cos_target_bucket_endpoint : var.enable_activity_tracker_event_routing_to_cos_bucket ? module.at_cos_bucket[0].buckets[local.activity_tracker_cos_target_bucket_name].s3_endpoint_private : null
  cos_target_name                         = var.cos_target_name != null ? var.cos_target_name : local.create_cos_instance ? module.cos[0].cos_instance_name : try("${local.prefix}-cos-target", "cos-target")
  cloud_logs_target_name                  = var.cloud_logs_target_name != null ? var.cloud_logs_target_name : local.create_cos_instance ? module.cos[0].cos_instance_name : try("${local.prefix}-cloud-logs-target", "cloud-logs-target")
  activity_tracker_cos_route_name         = var.activity_tracker_cos_route_name != null ? var.activity_tracker_cos_route_name : try("${local.prefix}at-cos-route", "at-cos-route")
  activity_tracker_cloud_logs_route_name  = var.activity_tracker_cloud_logs_route_name != null ? var.activity_tracker_cloud_logs_route_name : try("${local.prefix}at-cloud-logs-route", "at-cloud-logs-route")
  activity_tracker_bucket_config = var.existing_activity_tracker_cos_target_bucket_name == null && var.enable_activity_tracker_event_routing_to_cos_bucket ? {
    class = var.activity_tracker_cos_target_bucket_class
    name  = local.activity_tracker_cos_target_bucket_name
    tag   = var.activity_tracker_cos_bucket_access_tags
  } : null


  bucket_retention_configs = local.activity_tracker_bucket_config != null ? { (local.activity_tracker_cos_target_bucket_name) = var.activity_tracker_cos_bucket_retention_policy } : null

  at_buckets_config = local.activity_tracker_bucket_config != null ? [local.activity_tracker_bucket_config] : []

  archive_rule = length(local.at_buckets_config) != 0 ? {
    enable = true
    days   = 90
    type   = "Glacier"
  } : null

  expire_rule = length(local.at_buckets_config) != 0 ? {
    enable = true
    days   = 366
  } : null

  activity_tracker_cos_route = var.enable_activity_tracker_event_routing_to_cos_bucket ? [{
    route_name = local.activity_tracker_cos_route_name
    locations  = ["*"]
    target_ids = [module.activity_tracker.activity_tracker_targets[local.cos_target_name].id]
  }] : []

  activity_tracker_cloud_logs_route = var.enable_activity_tracker_event_routing_to_cloud_logs ? [{
    route_name = local.activity_tracker_cloud_logs_route_name
    locations  = ["*"]
    target_ids = [module.activity_tracker.activity_tracker_targets[local.cloud_logs_target_name].id]
  }] : []
  activity_tracker_routes = concat(local.activity_tracker_cos_route, local.activity_tracker_cloud_logs_route)

}

module "activity_tracker" {
  source  = "terraform-ibm-modules/activity-tracker/ibm"
  version = "1.5.0"
  cos_targets = var.enable_activity_tracker_event_routing_to_cos_bucket ? [
    {
      bucket_name                       = local.cos_target_bucket_name
      endpoint                          = local.cos_target_bucket_endpoint
      instance_id                       = var.existing_cos_instance_crn != null ? var.existing_cos_instance_crn : module.cos[0].cos_instance_crn
      target_region                     = var.region
      target_name                       = local.cos_target_name
      skip_atracker_cos_iam_auth_policy = var.skip_activity_tracker_cos_auth_policy
      service_to_service_enabled        = true
    }
  ] : []

  cloud_logs_targets = var.enable_activity_tracker_event_routing_to_cloud_logs ? [
    {
      instance_id   = var.existing_cloud_logs_crn != null ? var.existing_cloud_logs_crn : module.cloud_logs[0].crn
      target_region = var.region
      target_name   = local.cloud_logs_target_name
    }
  ] : []

  # Routes
  activity_tracker_routes = local.activity_tracker_routes
}

module "at_cos_bucket" {
  count   = length(coalesce(local.at_buckets_config, [])) != 0 ? 1 : 0 # no need to call COS module if consumer is using existing COS bucket
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "10.5.8"
  bucket_configs = [
    for value in local.at_buckets_config :
    {
      access_tags                   = value.tag
      bucket_name                   = value.name
      add_bucket_name_suffix        = var.append_random_bucket_name_suffix
      kms_guid                      = local.cluster_existing_kms_guid
      kms_encryption_enabled        = var.kms_encryption_enabled_buckets
      kms_key_crn                   = local.cluster_kms_key_crn
      skip_iam_authorization_policy = false
      management_endpoint_type      = var.management_endpoint_type_for_buckets
      storage_class                 = value.class
      resource_instance_id          = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].resource : module.cos[0].cos_instance_id
      region_location               = var.region
      force_delete                  = true
      archive_rule                  = local.archive_rule
      expire_rule                   = local.expire_rule
      retention_rule                = lookup(local.bucket_retention_configs, value.name, null)
      metrics_monitoring = {
        usage_metrics_enabled   = true
        request_metrics_enabled = true
        # If `existing_monitoring_crn` is not passed, metrics are sent to the instance associated to the container's location unless otherwise specified in the Metrics Router service configuration.
        metrics_monitoring_crn = var.existing_cloud_monitoring_crn != null ? var.existing_cloud_monitoring_crn : module.cloud_monitoring[0].crn
      }
      activity_tracking = {
        read_data_events  = true
        write_data_events = true
        management_events = true
      }
    }
  ]
}

########################################################################################################################
# App Config
########################################################################################################################
module "app_config" {
  source                                                     = "terraform-ibm-modules/app-configuration/ibm"
  version                                                    = "1.14.2"
  resource_group_id                                          = var.resource_group_id
  region                                                     = var.region
  app_config_name                                            = "${local.prefix}${var.app_config_name}"
  app_config_plan                                            = var.app_config_plan
  app_config_service_endpoints                               = var.app_config_service_endpoints
  app_config_tags                                            = var.app_config_tags
  app_config_collections                                     = var.app_config_collections
  enable_config_aggregator                                   = var.enable_config_aggregator
  config_aggregator_trusted_profile_name                     = "${local.prefix}${var.config_aggregator_trusted_profile_name}"
  config_aggregator_resource_collection_regions              = var.config_aggregator_resource_collection_regions
  config_aggregator_enterprise_id                            = var.config_aggregator_enterprise_id
  config_aggregator_enterprise_trusted_profile_name          = "${local.prefix}${var.config_aggregator_enterprise_trusted_profile_name}"
  config_aggregator_enterprise_trusted_profile_template_name = "${local.prefix}${var.config_aggregator_enterprise_trusted_profile_template_name}"
  config_aggregator_enterprise_account_group_ids_to_assign   = var.config_aggregator_enterprise_account_group_ids_to_assign
  config_aggregator_enterprise_account_ids_to_assign         = var.config_aggregator_enterprise_account_ids_to_assign
  cbr_rules                                                  = var.apprapp_cbr_rules
  kms_encryption_enabled                                     = var.kms_encryption_enabled_cluster
  skip_app_config_kms_auth_policy                            = var.skip_app_config_kms_auth_policy
  existing_kms_instance_crn                                  = var.existing_kms_instance_crn != null ? var.existing_kms_instance_crn : module.kms[0].key_protect_crn
  kms_endpoint_url                                           = (var.kms_encryption_enabled_boot_volume && var.existing_boot_volume_kms_key_crn == null) || (var.kms_encryption_enabled_cluster && var.existing_cluster_kms_key_crn == null) ? var.kms_endpoint_type == "private" ? module.kms[0].kms_private_endpoint : module.kms[0].kms_public_endpoint : var.kms_endpoint_url
  root_key_id                                                = local.cluster_kms_key_id
  enable_event_notifications                                 = true
  skip_app_config_event_notifications_auth_policy            = var.skip_app_config_event_notifications_auth_policy
  existing_event_notifications_instance_crn                  = local.eventnotification_crn
  event_notifications_endpoint_url                           = var.existing_event_notifications_instance_crn != null ? var.event_notifications_endpoint_url : var.en_service_endpoints == "private" ? module.event_notifications[0].event_notifications_private_endpoint : module.event_notifications[0].event_notifications_public_endpoint
  app_config_event_notifications_source_name                 = "${local.prefix}${var.app_config_event_notifications_source_name}"
  event_notifications_integration_description                = "The App Configuration integration to send notifications of events to users from the Event Notifications instance GUID ${local.existing_en_guid}"
}

#######################################################################################################################
# App Configuration Event Notifications Configuration
#######################################################################################################################

data "ibm_en_destinations" "en_apprapp_destinations" {
  instance_guid = local.existing_en_guid
}

resource "ibm_en_topic" "en_apprapp_topic" {
  depends_on    = [module.app_config]
  instance_guid = local.existing_en_guid
  name          = "Topic for App Configuration instance ${module.app_config.app_config_guid}"
  description   = "Topic for App Configuration events routing"
  sources {
    id = module.app_config.app_config_crn
    rules {
      enabled           = true
      event_type_filter = "$.*"
    }
  }
}

resource "ibm_en_subscription_email" "apprapp_email_subscription" {
  count          = length(var.event_notifications_email_list) > 0 ? 1 : 0
  instance_guid  = local.existing_en_guid
  name           = "Email for App Configuration Subscription"
  description    = "Subscription for App Configuration Events"
  destination_id = [for s in toset(data.ibm_en_destinations.en_apprapp_destinations[count.index].destinations) : s.id if s.type == "smtp_ibm"][0]
  topic_id       = ibm_en_topic.en_apprapp_topic[count.index].topic_id
  attributes {
    add_notification_payload = true
    reply_to_mail            = var.event_notifications_reply_to_email
    reply_to_name            = "App Configuration Event Notifications Bot"
    from_name                = var.event_notifications_from_email
    invited                  = var.event_notifications_email_list
  }
}

#################################################################################
# SCC Workload Protection
#################################################################################

locals {
  scc_workload_protection_instance_name     = "${local.prefix}${var.scc_workload_protection_instance_name}"
  scc_workload_protection_resource_key_name = "${local.prefix}${var.scc_workload_protection_instance_name}-key"
}

module "scc_wp" {
  source                                       = "terraform-ibm-modules/scc-workload-protection/ibm"
  version                                      = "1.16.4"
  name                                         = local.scc_workload_protection_instance_name
  region                                       = var.region
  resource_group_id                            = var.resource_group_id
  resource_tags                                = var.scc_workload_protection_instance_tags
  resource_key_name                            = local.scc_workload_protection_resource_key_name
  resource_key_tags                            = var.scc_workload_protection_resource_key_tags
  cloud_monitoring_instance_crn                = var.existing_cloud_monitoring_crn != null ? var.existing_cloud_monitoring_crn : module.cloud_monitoring[0].crn
  access_tags                                  = var.scc_workload_protection_access_tags
  scc_wp_service_plan                          = var.scc_workload_protection_service_plan
  app_config_crn                               = module.app_config.app_config_crn
  scc_workload_protection_trusted_profile_name = "${local.prefix}${var.scc_workload_protection_trusted_profile_name}"
  cbr_rules                                    = var.scc_wp_cbr_rules
  cspm_enabled                                 = var.cspm_enabled
}

#############################################################################
# COS Bucket for VPC flow logs
#############################################################################


locals {
  vpc_flow_logs_bucket_name = "${local.prefix}${var.flow_logs_cos_bucket_name}"
  # configuration for the flow logs bucket
  flow_logs_bucket_config = [{
    access_tags                   = var.vpc_flow_logs_access_tags
    bucket_name                   = local.vpc_flow_logs_bucket_name
    add_bucket_name_suffix        = var.append_random_bucket_name_suffix
    kms_encryption_enabled        = var.kms_encryption_enabled_buckets
    kms_guid                      = local.cluster_existing_kms_guid
    kms_key_crn                   = local.cluster_kms_key_crn
    skip_iam_authorization_policy = true
    management_endpoint_type      = var.management_endpoint_type_for_buckets
    storage_class                 = var.cos_buckets_class
    resource_instance_id          = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].resource : module.cos[0].cos_instance_id
    region_location               = var.region
    force_delete                  = true
    archive_rule = var.flow_logs_cos_bucket_archive_days != null ? {
      enable = true
      days   = var.flow_logs_cos_bucket_archive_days
      type   = var.flow_logs_cos_bucket_archive_type
    } : null
    expire_rule = var.flow_logs_cos_bucket_expire_days != null ? {
      enable = true
      days   = var.flow_logs_cos_bucket_expire_days
    } : null
    retention_rule = var.flow_logs_cos_bucket_enable_retention ? {
      default   = var.flow_logs_cos_bucket_default_retention_days
      maximum   = var.flow_logs_cos_bucket_maximum_retention_days
      minimum   = var.flow_logs_cos_bucket_minimum_retention_days
      permanent = var.flow_logs_cos_bucket_enable_permanent_retention
    } : null
    object_versioning_enabled = var.flow_logs_cos_bucket_enable_object_versioning
  }]
}

# Create COS bucket using the defined bucket configuration
module "vpc_cos_buckets" {
  count          = var.enable_vpc_flow_logs ? 1 : 0
  source         = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version        = "10.5.8"
  bucket_configs = local.flow_logs_bucket_config
}

#############################################################################
# VPC
#############################################################################

locals {
  # create 'use_public_gateways' object
  public_gateway_object = {
    for key, value in var.subnets : key => value != null ? length([for sub in value : sub.public_gateway if sub.public_gateway]) > 0 ? [for sub in value : sub.public_gateway if sub.public_gateway][0] : false : false
  }
}

# Create VPC
module "vpc" {
  source                                 = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version                                = "8.9.1"
  resource_group_id                      = var.resource_group_id
  region                                 = var.region
  create_vpc                             = true
  name                                   = var.vpc_name
  prefix                                 = local.prefix != "" ? trimspace(var.prefix) : null
  tags                                   = var.vpc_resource_tags
  access_tags                            = var.vpc_access_tags
  subnets                                = var.subnets
  default_network_acl_name               = var.default_network_acl_name
  default_security_group_name            = var.default_security_group_name
  default_routing_table_name             = var.default_routing_table_name
  network_acls                           = var.network_acls
  security_group_rules                   = var.security_group_rules
  clean_default_sg_acl                   = var.clean_default_security_group_acl
  use_public_gateways                    = local.public_gateway_object
  address_prefixes                       = var.address_prefixes
  routes                                 = var.routes
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = !var.skip_vpc_cos_iam_auth_policy
  existing_cos_instance_guid             = var.enable_vpc_flow_logs ? local.cos_instance_guid : null
  existing_storage_bucket_name           = var.enable_vpc_flow_logs ? module.vpc_cos_buckets[0].buckets[local.vpc_flow_logs_bucket_name].bucket_name : null
  vpn_gateways                           = var.vpn_gateways
}

#############################################################################
# VPE Gateway
#############################################################################

module "vpe_gateway" {
  source               = "terraform-ibm-modules/vpe-gateway/ibm"
  version              = "4.6.6"
  resource_group_id    = var.resource_group_id
  region               = var.region
  prefix               = local.prefix
  security_group_ids   = var.vpe_gateway_security_group_ids
  vpc_name             = module.vpc.vpc_name
  vpc_id               = module.vpc.vpc_id
  subnet_zone_list     = module.vpc.subnet_zone_list
  cloud_services       = var.vpe_gateway_cloud_services
  cloud_service_by_crn = var.vpe_gateway_cloud_service_by_crn
  service_endpoints    = var.vpe_gateway_service_endpoints
  reserved_ips         = var.vpe_gateway_reserved_ips
}

########################################################################################################################
# OCP VPC cluster
########################################################################################################################

locals {
  vpc_subnets = {
    # The default behavior is to deploy the worker pool across all subnets within the VPC.
    "default" = [
      for subnet in module.vpc.subnet_zone_list :
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
      resource_group_id = var.resource_group_id
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
    ], [for pool in var.additional_worker_pools : merge(pool, { resource_group_id = var.resource_group_id
      boot_volume_encryption_kms_config = {
        crk             = local.boot_volume_kms_key_id
        kms_instance_id = local.boot_volume_existing_kms_guid
        kms_account_id  = local.boot_volume_kms_account_id
    } }) if length(pool.vpc_subnets) > 0],
    [for pool in var.additional_worker_pools : {
      pool_name         = pool.pool_name
      machine_type      = pool.machine_type
      workers_per_zone  = pool.workers_per_zone
      resource_group_id = var.resource_group_id
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

  # Managing the ODF version accordingly, as it changes with each OCP version.
  addons = lookup(var.addons, "openshift-data-foundation", null) != null ? lookup(var.addons["openshift-data-foundation"], "version", null) == null ? { for key, value in var.addons :
    key => value != null ? {
      version         = lookup(value, "version", null) == null && key == "openshift-data-foundation" ? "${var.openshift_version}.0" : lookup(value, "version", null)
      parameters_json = lookup(value, "parameters_json", null)
  } : null } : var.addons : var.addons
}

module "ocp_base" {
  source                                   = "../.."
  resource_group_id                        = var.resource_group_id
  region                                   = var.region
  tags                                     = var.cluster_resource_tags
  cluster_name                             = local.cluster_name
  force_delete_storage                     = true
  use_existing_cos                         = true
  existing_cos_id                          = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].resource : module.cos[0].cos_instance_crn
  vpc_id                                   = module.vpc.vpc_id
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
  kms_config                               = local.kms_config
  manage_all_addons                        = var.manage_all_addons
  number_of_lbs                            = var.number_of_lbs
  pod_subnet_cidr                          = var.pod_subnet_cidr
  service_subnet_cidr                      = var.service_subnet_cidr
  verify_worker_network_readiness          = var.verify_worker_network_readiness
  worker_pools_taints                      = var.worker_pools_taints
  enable_secrets_manager_integration       = var.enable_secrets_manager_integration
  existing_secrets_manager_instance_crn    = local.secrets_manager_crn
  secrets_manager_secret_group_id          = var.secrets_manager_secret_group_id != null ? var.secrets_manager_secret_group_id : (var.enable_secrets_manager_integration ? module.secret_group[0].secret_group_id : null)
  skip_ocp_secrets_manager_iam_auth_policy = var.skip_ocp_secrets_manager_iam_auth_policy
}

resource "terraform_data" "delete_secrets" {
  count = var.enable_secrets_manager_integration && var.secrets_manager_secret_group_id == null ? 1 : 0
  input = {
    secret_id                   = module.secret_group[0].secret_group_id
    provider_visibility         = var.provider_visibility
    secrets_manager_instance_id = local.secrets_manager_guid
    secrets_manager_region      = local.secrets_manager_region
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
  region                   = local.secrets_manager_region
  secrets_manager_guid     = local.secrets_manager_guid
  secret_group_name        = module.ocp_base.cluster_id
  secret_group_description = "Secret group for storing ingress certificates for cluster ${local.cluster_name} with id: ${module.ocp_base.cluster_id}"
  endpoint_type            = var.secrets_manager_endpoint_type
}
