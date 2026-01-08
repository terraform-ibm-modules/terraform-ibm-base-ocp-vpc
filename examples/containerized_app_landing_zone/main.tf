#########################################################################################################
# Resource group
#########################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.7"
  existing_resource_group_name = var.existing_resource_group_name
}

#########################################################################################################
# KMS
#########################################################################################################

locals {
  cluster_key_ring_name     = "${var.prefix}-cluster-key-ring"
  cluster_key_name          = "${var.prefix}-cluster-key"
  boot_volume_key_ring_name = "${var.prefix}-boot-volume-key-ring"
  boot_volume_key_name      = "${var.prefix}-boot-volume-key"
  keys = [{
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
    },
    {
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
    }
  ]
}


module "kms" {
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "5.5.20"
  resource_group_id           = module.resource_group.resource_group_id
  region                      = var.region
  create_key_protect_instance = true
  key_protect_instance_name   = "${var.prefix}-key-protect"
  key_protect_plan            = "tiered-pricing"
  enable_metrics              = true
  key_protect_allowed_network = "private-only" # Possible values are 'private-only', or 'public-and-private'.
  key_ring_endpoint_type      = "private"      # Possible values are `public` or `private`.
  key_endpoint_type           = "private"      # Possible values are `public` or `private`.
  keys                        = [for key in local.keys : key if key != null]
}

#########################################################################################################
# Cloud Monitoring
#########################################################################################################

locals {
  default_metrics_router_route = [{
    name = "${var.prefix}-metrics-routing-route"
    rules = [{
      action = "send"
      targets = [{
        id = module.metrics_routing.metrics_router_targets["${var.prefix}-cloud-monitoring-target"].id
      }]
      inclusion_filters = []
    }]
  }]
}

module "cloud_monitoring" {
  source                      = "terraform-ibm-modules/cloud-monitoring/ibm"
  version                     = "1.12.15"
  resource_group_id           = module.resource_group.resource_group_id
  region                      = var.region
  instance_name               = "${var.prefix}-cloud-monitoring"
  plan                        = "graduated-tier" # Possible values are `lite` and `graduated-tier` and graduated-tier-sysdig-secure-plus-monitor (available in region eu-fr2 only).
  service_endpoints           = "public-and-private"
  disable_access_key_creation = false
  enable_platform_metrics     = false
}

module "metrics_routing" {
  source  = "terraform-ibm-modules/cloud-monitoring/ibm//modules/metrics_routing"
  version = "1.12.15"
  metrics_router_targets = [
    {
      destination_crn                 = module.cloud_monitoring.crn
      target_name                     = "${var.prefix}-cloud-monitoring-target"
      target_region                   = var.region
      skip_metrics_router_auth_policy = false
    }
  ]

  metrics_router_routes   = local.default_metrics_router_route
  metrics_router_settings = { primary_metadata_region = var.region }
}

#########################################################################################################
# Event Notifications
#########################################################################################################

locals {
  en_cos_bucket_name = "${var.prefix}-base-event-notifications-bucket"
}

module "event_notifications" {
  source            = "terraform-ibm-modules/event-notifications/ibm"
  version           = "2.10.34"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  name              = "${var.prefix}-event-notifications"
  plan              = "standard"           # Possible values are `lite`, `standard`.
  service_endpoints = "public-and-private" # Possible values are `public`, `private`, `public-and-private`.
  # KMS Related
  kms_encryption_enabled    = true
  kms_endpoint_url          = module.kms.kms_private_endpoint
  existing_kms_instance_crn = module.kms.key_protect_crn
  root_key_id               = module.kms.keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].key_id
  skip_en_kms_auth_policy   = false
  # COS Related
  cos_integration_enabled = true
  cos_bucket_name         = module.en_cos_buckets.buckets[local.en_cos_bucket_name].bucket_name
  cos_instance_id         = module.cos.cos_instance_id
  skip_en_cos_auth_policy = false
  cos_endpoint            = "https://${module.en_cos_buckets.buckets[local.en_cos_bucket_name].s3_endpoint_direct}"
}

locals {
  en_cos_bucket_config = [{
    bucket_name                   = local.en_cos_bucket_name
    add_bucket_name_suffix        = true
    kms_encryption_enabled        = true
    kms_guid                      = module.kms.kms_guid
    kms_key_crn                   = module.kms.keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].crn
    skip_iam_authorization_policy = false
    management_endpoint_type      = "direct" # Possible values are `public`, `private` or `direct`.
    storage_class                 = "smart"  # Possible values are `standard` or `smart`.
    resource_instance_id          = module.cos.cos_instance_id
    region_location               = var.region
    activity_tracking = {
      read_data_events  = true
      write_data_events = true
      management_events = true
    }
    metrics_monitoring = {
      usage_metrics_enabled   = true
      request_metrics_enabled = true
      metrics_monitoring_crn  = module.cloud_monitoring.crn
    }
    force_delete = true
  }]
}

module "en_cos_buckets" {
  source         = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version        = "10.8.3"
  bucket_configs = local.en_cos_bucket_config
}

#########################################################################################################
# Service Credentials
#########################################################################################################

# create a service authorization between Secrets Manager and the target service (Event Notification)
resource "ibm_iam_authorization_policy" "en_secrets_manager_key_manager" {
  source_service_name         = "secrets-manager"
  source_resource_instance_id = module.secrets_manager.secrets_manager_guid
  target_service_name         = "event-notifications"
  target_resource_instance_id = module.event_notifications.guid
  roles                       = ["Key Manager"]
  description                 = "Allow Secrets Manager instance to manage key for the event-notification instance"
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_en_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.en_secrets_manager_key_manager]
  create_duration = "30s"
}

#########################################################################################################
# Secrets Manager
#########################################################################################################

locals {
  secret_groups = [
    {
      secret_group_name        = "General"
      secret_group_description = "A general purpose secrets group with an associated access group which has a secrets reader role"
      create_access_group      = true
      access_group_name        = "general-secrets-group-access-group"
      access_group_roles       = ["SecretsReader"]
    }
  ]
  secret_groups_with_prefix = [
    for group in local.secret_groups : merge(group, {
      access_group_name = group.access_group_name != null ? "${var.prefix}-${group.access_group_name}" : null
    })
  ]
  # parsed_existing_en_instance_crn = split(":", module.event_notifications.crn)
  # existing_en_guid                = length(local.parsed_existing_en_instance_crn) > 0 ? local.parsed_existing_en_instance_crn[7] : null
}

module "secrets_manager" {
  source                        = "terraform-ibm-modules/secrets-manager/ibm"
  version                       = "2.12.16"
  resource_group_id             = module.resource_group.resource_group_id
  region                        = var.region
  secrets_manager_name          = "${var.prefix}-secrets-manager"
  sm_service_plan               = "standard" # Possible values are `standard` or `trial`.
  skip_iam_authorization_policy = false
  # kms dependency
  is_hpcs_key                       = false
  kms_encryption_enabled            = true
  kms_key_crn                       = module.kms.keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].crn
  skip_kms_iam_authorization_policy = false
  # event notifications dependency
  enable_event_notification        = true
  existing_en_instance_crn         = module.event_notifications.crn
  skip_en_iam_authorization_policy = false
  endpoint_type                    = "private"      # Possible values are `public` or `private`.
  allowed_network                  = "private-only" # Possible values are 'private-only', or 'public-and-private'.
  secrets                          = local.secret_groups_with_prefix
}

#########################################################################################################
# Secrets Manager Event Notifications Configuration
#########################################################################################################

data "ibm_en_destinations" "en_sm_destinations" {
  instance_guid = module.event_notifications.guid
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/5533
resource "time_sleep" "wait_for_secrets_manager" {
  depends_on      = [module.secrets_manager]
  create_duration = "30s"
}

resource "ibm_en_topic" "en_sm_topic" {
  depends_on    = [time_sleep.wait_for_secrets_manager]
  instance_guid = module.event_notifications.guid
  name          = "Topic for Secrets Manager instance ${module.secrets_manager.secrets_manager_guid}"
  description   = "Topic for Secrets Manager events routing"
  sources {
    id = module.secrets_manager.secrets_manager_crn
    rules {
      enabled           = true
      event_type_filter = "$.*"
    }
  }
}

resource "ibm_en_subscription_email" "en_email_subscription" {
  count          = length(var.event_notifications_email_list) > 0 ? 1 : 0
  instance_guid  = module.event_notifications.guid
  name           = "Email for Secrets Manager Subscription"
  description    = "Subscription for Secret Manager Events"
  destination_id = [for s in toset(data.ibm_en_destinations.en_sm_destinations.destinations) : s.id if s.type == "smtp_ibm"][0]
  topic_id       = ibm_en_topic.en_sm_topic.topic_id
  attributes {
    add_notification_payload = true
    reply_to_mail            = "no-reply@ibm.com"
    reply_to_name            = "Secret Manager Event Notifications Bot"
    from_name                = "compliancealert@ibm.com"
    invited                  = var.event_notifications_email_list
  }
}

#########################################################################################################
# COS
#########################################################################################################

module "cos" {
  source              = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version             = "10.8.3"
  resource_group_id   = module.resource_group.resource_group_id
  create_cos_instance = true
  cos_instance_name   = "${var.prefix}-cos-instance"
  cos_plan            = "standard" # Possible values are `standard` or `cos-one-rate-plan`.
}

#########################################################################################################
# Secrets Manager service credentials for COS
#########################################################################################################

# create s2s auth policy with Secrets Manager
resource "ibm_iam_authorization_policy" "cos_secrets_manager_key_manager" {
  source_service_name         = "secrets-manager"
  source_resource_instance_id = module.secrets_manager.secrets_manager_guid
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = module.cos.cos_instance_guid
  roles                       = ["Key Manager"]
  description                 = "Allow Secrets Manager with instance id ${module.secrets_manager.secrets_manager_guid} to manage key for the COS instance"
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_cos_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.cos_secrets_manager_key_manager]
  create_duration = "30s"
}

#########################################################################################################
# Cloud Logs
#########################################################################################################

locals {
  data_bucket_name    = "${var.prefix}-cloud-logs-logs-bucket"
  metrics_bucket_name = "${var.prefix}-cloud-logs-metrics-bucket"
}

module "cloud_logs" {
  depends_on        = [time_sleep.wait_for_cos_authorization_policy]
  source            = "terraform-ibm-modules/cloud-logs/ibm"
  version           = "1.10.19"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  instance_name     = "${var.prefix}-cloud-logs"
  plan              = "standard"           # not a variable because there is only one option
  service_endpoints = "public-and-private" # not a variable because there is only one option
  data_storage = {
    logs_data = {
      enabled              = true
      bucket_crn           = module.cloud_logs_buckets.buckets[local.data_bucket_name].bucket_crn
      bucket_endpoint      = module.cloud_logs_buckets.buckets[local.data_bucket_name].s3_endpoint_direct
      skip_cos_auth_policy = false
    },
    metrics_data = {
      enabled              = true
      bucket_crn           = module.cloud_logs_buckets.buckets[local.metrics_bucket_name].bucket_crn
      bucket_endpoint      = module.cloud_logs_buckets.buckets[local.metrics_bucket_name].s3_endpoint_direct
      skip_cos_auth_policy = false
    }
  }
  skip_logs_routing_auth_policy = false
}

module "cloud_logs_buckets" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "10.8.3"
  bucket_configs = [
    {
      bucket_name              = local.data_bucket_name
      kms_key_crn              = module.kms.keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].crn
      kms_guid                 = module.kms.kms_guid
      kms_encryption_enabled   = false
      region_location          = var.region
      resource_instance_id     = module.cos.cos_instance_id
      add_bucket_name_suffix   = true
      management_endpoint_type = "direct"
      storage_class            = "smart"
      force_delete             = true # If this is set to false, and the bucket contains data, the destroy will fail. Setting it to false on destroy has no impact, it has to be set on apply, so hence hard coding to true."
      activity_tracking = {
        read_data_events  = true
        write_data_events = true
        management_events = true
      }
      metrics_monitoring = {
        usage_metrics_enabled   = true
        request_metrics_enabled = true
        metrics_monitoring_crn  = module.cloud_monitoring.crn
      }
    },
    {
      bucket_name                   = local.metrics_bucket_name
      kms_key_crn                   = module.kms.keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].crn
      kms_guid                      = module.kms.kms_guid
      kms_encryption_enabled        = false
      region_location               = var.region
      resource_instance_id          = module.cos.cos_instance_id
      add_bucket_name_suffix        = true
      management_endpoint_type      = "direct"
      storage_class                 = "smart"
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
        metrics_monitoring_crn  = module.cloud_monitoring.crn
      }
    }
  ]
}

#########################################################################################################
# Activity Tracker
#########################################################################################################

locals {
  activity_tracker_bucket_config = {
    class = "smart"
    name  = local.activity_tracker_cos_target_bucket_name
  }

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
  activity_tracker_cos_target_bucket_name = "${var.prefix}-at-events-cos-bucket"
  activity_tracker_cos_route = [{
    route_name = "${var.prefix}-at-cos-route"
    locations  = ["*"]
    target_ids = [module.activity_tracker.activity_tracker_targets[module.cos.cos_instance_name].id]
  }]
  activity_tracker_cloud_logs_route = [{
    route_name = "${var.prefix}-at-cloud-logs-route"
    locations  = ["*"]
    target_ids = [module.activity_tracker.activity_tracker_targets[module.cos.cos_instance_name].id]
  }]
  activity_tracker_routes = concat(local.activity_tracker_cos_route, local.activity_tracker_cloud_logs_route)
}

module "activity_tracker" {
  source  = "terraform-ibm-modules/activity-tracker/ibm"
  version = "1.5.20"
  cos_targets = [
    {
      bucket_name                       = module.at_cos_bucket.buckets[local.activity_tracker_cos_target_bucket_name].bucket_name
      endpoint                          = module.at_cos_bucket.buckets[local.activity_tracker_cos_target_bucket_name].s3_endpoint_private
      instance_id                       = module.cos.cos_instance_crn
      target_region                     = var.region
      target_name                       = module.cos.cos_instance_name
      skip_atracker_cos_iam_auth_policy = false
      service_to_service_enabled        = true
    }
  ]

  cloud_logs_targets = [
    {
      instance_id   = module.cloud_logs.crn
      target_region = var.region
      target_name   = module.cos.cos_instance_name
    }
  ]

  # Routes
  activity_tracker_routes = local.activity_tracker_routes
}

module "at_cos_bucket" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "10.8.3"
  bucket_configs = [
    for value in local.at_buckets_config :
    {
      bucket_name                   = value.name
      add_bucket_name_suffix        = true
      kms_guid                      = module.kms.kms_guid
      kms_encryption_enabled        = false
      kms_key_crn                   = module.kms.keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].crn
      skip_iam_authorization_policy = false
      management_endpoint_type      = "direct"
      storage_class                 = "smart"
      resource_instance_id          = module.cos.cos_instance_id
      region_location               = var.region
      force_delete                  = true
      archive_rule                  = local.archive_rule
      expire_rule                   = local.expire_rule
      metrics_monitoring = {
        usage_metrics_enabled   = true
        request_metrics_enabled = true
        # If `existing_monitoring_crn` is not passed, metrics are sent to the instance associated to the container's location unless otherwise specified in the Metrics Router service configuration.
        metrics_monitoring_crn = module.cloud_monitoring.crn
      }
      activity_tracking = {
        read_data_events  = true
        write_data_events = true
        management_events = true
      }
    }
  ]
}

#########################################################################################################
# App Config
#########################################################################################################

module "app_config" {
  source                                                     = "terraform-ibm-modules/app-configuration/ibm"
  version                                                    = "1.14.7"
  resource_group_id                                          = module.resource_group.resource_group_id
  region                                                     = var.region
  app_config_name                                            = "${var.prefix}-app-config"
  app_config_plan                                            = "enterprise"
  app_config_service_endpoints                               = "public-and-private" # Possible values are `public` or `public-and-private`.
  enable_config_aggregator                                   = true
  config_aggregator_trusted_profile_name                     = "${var.prefix}-config-aggregator-trusted-profile"
  config_aggregator_resource_collection_regions              = ["all"]
  config_aggregator_enterprise_trusted_profile_name          = "${var.prefix}-config-aggregator-enterprise-trusted-profile"
  config_aggregator_enterprise_trusted_profile_template_name = "${var.prefix}-config-aggregator-trusted-profile-template"
  config_aggregator_enterprise_account_group_ids_to_assign   = ["all"]
  kms_encryption_enabled                                     = true
  skip_app_config_kms_auth_policy                            = false
  existing_kms_instance_crn                                  = module.kms.key_protect_crn
  kms_endpoint_url                                           = module.kms.kms_private_endpoint
  root_key_id                                                = module.kms.keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].key_id
  enable_event_notifications                                 = true
  skip_app_config_event_notifications_auth_policy            = false
  existing_event_notifications_instance_crn                  = module.event_notifications.crn
  event_notifications_endpoint_url                           = module.event_notifications.event_notifications_private_endpoint
  app_config_event_notifications_source_name                 = "${var.prefix}-app-config-en"
  event_notifications_integration_description                = "The App Configuration integration to send notifications of events to users from the Event Notifications instance GUID ${module.event_notifications.guid}"
}

#########################################################################################################
# App Configuration Event Notifications Configuration
#########################################################################################################

data "ibm_en_destinations" "en_apprapp_destinations" {
  instance_guid = module.event_notifications.guid
}

resource "ibm_en_topic" "en_apprapp_topic" {
  depends_on    = [module.app_config]
  instance_guid = module.event_notifications.guid
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
  instance_guid  = module.event_notifications.guid
  name           = "Email for App Configuration Subscription"
  description    = "Subscription for App Configuration Events"
  destination_id = [for s in toset(data.ibm_en_destinations.en_apprapp_destinations.destinations) : s.id if s.type == "smtp_ibm"][0]
  topic_id       = ibm_en_topic.en_apprapp_topic.topic_id
  attributes {
    add_notification_payload = true
    reply_to_mail            = "no-reply@ibm.com"
    reply_to_name            = "App Configuration Event Notifications Bot"
    from_name                = "compliancealert@ibm.com"
    invited                  = var.event_notifications_email_list
  }
}

#########################################################################################################
# SCC Workload Protection
#########################################################################################################

module "scc_wp" {
  source                                       = "terraform-ibm-modules/scc-workload-protection/ibm"
  version                                      = "1.16.17"
  name                                         = "${var.prefix}-scc-workload-protection"
  region                                       = var.region
  resource_group_id                            = module.resource_group.resource_group_id
  resource_key_name                            = "${var.prefix}-scc-workload-protection-key"
  cloud_monitoring_instance_crn                = module.cloud_monitoring.crn
  scc_wp_service_plan                          = "graduated-tier" # Possible values are `free-trial` or `graduated-tier`.
  app_config_crn                               = module.app_config.app_config_crn
  scc_workload_protection_trusted_profile_name = "${var.prefix}-workload-protection-trusted-profile"
  cspm_enabled                                 = true
}

#########################################################################################################
# COS Bucket for VPC flow logs
#########################################################################################################


locals {
  vpc_flow_logs_bucket_name = "${var.prefix}-flow-logs-bucket"
  # configuration for the flow logs bucket
  flow_logs_bucket_config = [{
    bucket_name                   = local.vpc_flow_logs_bucket_name
    add_bucket_name_suffix        = true
    kms_encryption_enabled        = false
    kms_guid                      = module.kms.kms_guid
    kms_key_crn                   = module.kms.keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].crn
    skip_iam_authorization_policy = true
    management_endpoint_type      = "direct"
    storage_class                 = "smart"
    resource_instance_id          = module.cos.cos_instance_id
    region_location               = var.region
    force_delete                  = true
    archive_rule = {
      enable = true
      days   = 90
      type   = "Glacier" # Possible values are `Glacier` or `Accelerated`.
    }
    expire_rule = {
      enable = true
      days   = 366
    }
    object_versioning_enabled = false
  }]
}

# Create COS bucket using the defined bucket configuration
module "vpc_cos_buckets" {
  source         = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version        = "10.8.3"
  bucket_configs = local.flow_logs_bucket_config
}

#########################################################################################################
# VPC
#########################################################################################################

locals {
  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
        no_addr_prefix = false
      }
    ],
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
        no_addr_prefix = false
      }
    ],
    zone-3 = [
      {
        name           = "subnet-c"
        cidr           = "10.30.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
        no_addr_prefix = false
      }
    ]
  }

  network_acls = [
    {
      name                         = "vpc-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules = [
        {
          name      = "allow-443-inbound-source"
          action    = "allow"
          direction = "inbound"
          tcp = {
            source_port_min = 443
            source_port_max = 443
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-443-inbound-dest"
          action    = "allow"
          direction = "inbound"
          tcp = {
            port_max = 443
            port_min = 443
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-all-80-inbound"
          action    = "allow"
          direction = "inbound"
          tcp = {
            source_port_min = 80
            source_port_max = 80
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-all-ingress-inbound"
          action    = "allow"
          direction = "inbound"
          tcp = {
            source_port_min = 30000
            source_port_max = 32767
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-443-outbound-source"
          action    = "allow"
          direction = "outbound"
          tcp = {
            source_port_min = 443
            source_port_max = 443
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-443-outbound-dest"
          action    = "allow"
          direction = "outbound"
          tcp = {
            port_min = 443
            port_max = 443
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-all-80-outbound"
          action    = "allow"
          direction = "outbound"
          tcp = {
            port_min = 80
            port_max = 80
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-all-ingress-outbound"
          action    = "allow"
          direction = "outbound"
          tcp = {
            port_min = 30000
            port_max = 32767
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        }
      ]
    }
  ]
  # create 'use_public_gateways' object
  public_gateway_object = {
    for key, value in local.subnets : key => value != null ? length([for sub in value : sub.public_gateway if sub.public_gateway]) > 0 ? [for sub in value : sub.public_gateway if sub.public_gateway][0] : false : false
  }
}

# Create VPC
module "vpc" {
  source               = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version              = "8.10.4"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  create_vpc           = true
  name                 = "vpc"
  prefix               = var.prefix
  subnets              = local.subnets
  network_acls         = local.network_acls
  clean_default_sg_acl = true
  use_public_gateways  = local.public_gateway_object
  address_prefixes = {
    zone-1 = null
    zone-2 = null
    zone-3 = null
  }
  enable_vpc_flow_logs                   = true
  create_authorization_policy_vpc_to_cos = true
  existing_cos_instance_guid             = module.cos.cos_instance_guid
  existing_storage_bucket_name           = module.vpc_cos_buckets.buckets[local.vpc_flow_logs_bucket_name].bucket_name
}

#########################################################################################################
# VPE Gateway
#########################################################################################################

module "vpe_gateway" {
  source            = "terraform-ibm-modules/vpe-gateway/ibm"
  version           = "4.8.19"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  vpc_name          = module.vpc.vpc_name
  vpc_id            = module.vpc.vpc_id
  subnet_zone_list  = module.vpc.subnet_zone_list
  service_endpoints = "private" # Possible values are `private` or `public`.
}

#########################################################################################################
# OCP VPC cluster
#########################################################################################################

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

  worker_pools = [
    {
      subnet_prefix     = "default"
      pool_name         = "default"
      machine_type      = "bx2.4x16"
      workers_per_zone  = 1
      resource_group_id = module.resource_group.resource_group_id
      operating_system  = "RHCOS"
      minSize           = 1
      maxSize           = 3
      enableAutoscaling = false
      boot_volume_encryption_kms_config = {
        crk             = module.kms.keys[format("%s.%s", local.boot_volume_key_ring_name, local.boot_volume_key_name)].key_id
        kms_instance_id = module.kms.kms_guid
        kms_account_id  = module.kms.kms_account_id
      }
      additional_security_group_ids = []
    }
  ]
  cluster_name = "${var.prefix}-openshift"
  kms_config = {
    crk_id           = module.kms.keys[format("%s.%s", local.cluster_key_ring_name, local.cluster_key_name)].key_id
    instance_id      = module.kms.kms_guid
    private_endpoint = true
    account_id       = module.kms.kms_account_id
  }
}

module "ocp_base" {
  source                                = "../.."
  resource_group_id                     = module.resource_group.resource_group_id
  region                                = var.region
  cluster_name                          = local.cluster_name
  force_delete_storage                  = true
  use_existing_cos                      = true
  existing_cos_id                       = module.cos.cos_instance_crn
  vpc_id                                = module.vpc.vpc_id
  vpc_subnets                           = local.vpc_subnets
  worker_pools                          = local.worker_pools
  kms_config                            = local.kms_config
  existing_secrets_manager_instance_crn = module.secrets_manager.secrets_manager_crn
  secrets_manager_secret_group_id       = module.secret_group.secret_group_id
}

resource "terraform_data" "delete_secrets" {
  input = {
    secret_id                   = module.secret_group.secret_group_id
    provider_visibility         = var.provider_visibility
    secrets_manager_instance_id = module.secrets_manager.secrets_manager_guid
    secrets_manager_region      = module.secrets_manager.secrets_manager_region
    secrets_manager_endpoint    = "private"
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
  source                   = "terraform-ibm-modules/secrets-manager-secret-group/ibm"
  version                  = "1.3.36"
  region                   = module.secrets_manager.secrets_manager_region
  secrets_manager_guid     = module.secrets_manager.secrets_manager_guid
  secret_group_name        = module.ocp_base.cluster_id
  secret_group_description = "Secret group for storing ingress certificates for cluster ${local.cluster_name} with id: ${module.ocp_base.cluster_id}"
  endpoint_type            = "private"
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_base.cluster_id
  resource_group_id = module.resource_group.resource_group_id
  config_dir        = "${path.module}/kubeconfig"
}

#########################################################################################################
# Monitoring Agents
#########################################################################################################

module "monitoring_agent" {
  source                    = "terraform-ibm-modules/monitoring-agent/ibm"
  version                   = "1.19.2"
  cluster_id                = module.ocp_base.cluster_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  is_vpc_cluster            = true
  access_key                = module.cloud_monitoring.access_key
  instance_region           = var.region
  metrics_filter            = [{ exclude = "metricA.*" }, { include = "metricB.*" }]
  container_filter          = [{ type = "exclude", parameter = "kubernetes.namespace.name", name = "kube-system" }]
  blacklisted_ports         = [22, 2379, 3306]
  agent_tags                = { "environment" : "test", "custom" : "value" }
  agent_mode                = "troubleshooting"
}

#########################################################################################################
# Logs Agent
#########################################################################################################

locals {
  logs_agent_namespace = "ibm-observe"
  logs_agent_name      = "logs-agent"
}

module "trusted_profile" {
  source                      = "terraform-ibm-modules/trusted-profile/ibm"
  version                     = "3.2.17"
  trusted_profile_name        = "${var.prefix}-profile"
  trusted_profile_description = "Logs agent Trusted Profile"
  trusted_profile_policies = [{
    roles             = ["Sender"]
    unique_identifier = "logs-agent"
    resources = [{
      service = "logs"
    }]
  }]
  trusted_profile_links = [{
    cr_type           = "ROKS_SA"
    unique_identifier = "logs-agent-link"
    links = [{
      crn       = module.ocp_base.cluster_crn
      namespace = local.logs_agent_namespace
      name      = local.logs_agent_name
    }]
    }
  ]
}

module "logs_agent" {
  source                        = "terraform-ibm-modules/logs-agent/ibm"
  version                       = "1.16.3"
  cluster_id                    = module.ocp_base.cluster_id
  cluster_resource_group_id     = module.resource_group.resource_group_id
  logs_agent_trusted_profile_id = module.trusted_profile.trusted_profile.id
  logs_agent_namespace          = local.logs_agent_namespace
  logs_agent_name               = local.logs_agent_name
  cloud_logs_ingress_endpoint   = module.cloud_logs.ingress_private_endpoint
  cloud_logs_ingress_port       = 3443
  logs_agent_additional_metadata = [{
    key   = "cluster_id"
    value = module.ocp_base.cluster_id
  }]
  logs_agent_resources = {
    limits = {
      cpu    = "500m"
      memory = "3Gi"
    }
    requests = {
      cpu    = "100m"
      memory = "1Gi"
    }
  }
  logs_agent_system_logs = ["/logs/*.log"]
}
