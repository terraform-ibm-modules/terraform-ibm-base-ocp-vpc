#######################################################################################################################
# Resource Group
#######################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.3.0"
  existing_resource_group_name = var.existing_resource_group_name
}

#######################################################################################################################
# IBM Cloud Logs
#######################################################################################################################

locals {
  prefix                   = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  cloud_logs_instance_name = "${local.prefix}${var.cloud_logs_instance_name}"
  create_cloud_logs        = var.existing_cloud_logs_crn == null
  cloud_logs_crn           = local.create_cloud_logs ? module.cloud_logs[0].crn : var.existing_cloud_logs_crn
  # Even though we're only performing a comparison (var.ibmcloud_cos_api_key != null),
  # Terraform treats the entire value as "tainted" due to sensitivity.
  # Later, in the cloud_logs module, where the data_storage input variable is used in a for_each loop,
  # the loop fails with the error: "Sensitive values, or values derived from sensitive values, cannot be used as for_each arguments."
  # However, since we use nonsensitive() solely for logical comparison, we are not exposing any secret values to logs and it's safe to use. Issue https://github.ibm.com/GoldenEye/issues/issues/13562.
  skip_cos_auth_policy = nonsensitive(var.ibmcloud_cos_api_key) != null ? true : var.skip_cloud_logs_cos_auth_policy
}

module "cloud_logs" {
  depends_on                             = [time_sleep.wait_for_cos_authorization_policy[0]]
  count                                  = local.create_cloud_logs ? 1 : 0
  source                                 = "terraform-ibm-modules/cloud-logs/ibm"
  version                                = "1.6.29"
  resource_group_id                      = module.resource_group.resource_group_id
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
      bucket_crn           = module.buckets.buckets[local.data_bucket_name].bucket_crn
      bucket_endpoint      = module.buckets.buckets[local.data_bucket_name].s3_endpoint_direct
      skip_cos_auth_policy = local.skip_cos_auth_policy
    },
    metrics_data = {
      enabled              = true
      bucket_crn           = module.buckets.buckets[local.metrics_bucket_name].bucket_crn
      bucket_endpoint      = module.buckets.buckets[local.metrics_bucket_name].s3_endpoint_direct
      skip_cos_auth_policy = local.skip_cos_auth_policy
    }
  }
  logs_routing_tenant_regions   = var.logs_routing_tenant_regions
  skip_logs_routing_auth_policy = var.skip_logs_routing_auth_policy
  policies                      = var.logs_policies
}

#######################################################################################################################
# COS
#######################################################################################################################

locals {
  use_kms_module    = var.kms_encryption_enabled_buckets && var.existing_kms_key_crn == null
  kms_region        = var.kms_encryption_enabled_buckets ? var.existing_kms_key_crn != null ? module.existing_kms_key_crn_parser[0].region : module.existing_kms_crn_parser[0].region : null
  existing_kms_guid = var.kms_encryption_enabled_buckets ? var.existing_kms_key_crn != null ? module.existing_kms_key_crn_parser[0].service_instance : module.existing_kms_crn_parser[0].service_instance : null
  kms_service_name  = var.kms_encryption_enabled_buckets ? var.existing_kms_key_crn != null ? module.existing_kms_key_crn_parser[0].service_name : module.existing_kms_crn_parser[0].service_name : null
  kms_account_id    = var.kms_encryption_enabled_buckets ? var.existing_kms_key_crn != null ? module.existing_kms_key_crn_parser[0].account_id : module.existing_kms_crn_parser[0].account_id : null

  data_bucket_name    = "${local.prefix}${var.cloud_logs_data_cos_bucket_name}"
  metrics_bucket_name = "${local.prefix}${var.cloud_logs_metrics_cos_bucket_name}"
  cos_instance_guid   = module.existing_cos_instance_crn_parser.service_instance

  key_ring_name = local.use_kms_module ? "${local.prefix}${var.cloud_logs_cos_key_ring_name}" : null
  key_name      = local.use_kms_module ? "${local.prefix}${var.cloud_logs_cos_key_name}" : null
  kms_key_crn   = var.kms_encryption_enabled_buckets ? var.existing_kms_key_crn != null ? var.existing_kms_key_crn : module.kms[0].keys[format("%s.%s", local.key_ring_name, local.key_name)].crn : null
  kms_key_id    = var.existing_kms_key_crn != null ? module.existing_kms_key_crn_parser[0].resource : var.existing_kms_instance_crn != null ? module.kms[0].keys[format("%s.%s", local.key_ring_name, local.key_name)].key_id : null

  create_cross_account_auth_policy     = var.existing_cloud_logs_crn == null ? !var.skip_cos_kms_iam_auth_policy && var.ibmcloud_kms_api_key == null && var.ibmcloud_cos_api_key == null ? false : true : false
  create_cross_account_cos_auth_policy = var.existing_cloud_logs_crn == null && var.ibmcloud_cos_api_key != null && !var.skip_cloud_logs_cos_auth_policy
  is_same_cross_account                = var.ibmcloud_kms_api_key == var.ibmcloud_cos_api_key
}

module "existing_cos_instance_crn_parser" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.2.0"
  crn     = var.existing_cos_instance_crn
}

module "buckets" {
  providers = {
    ibm = ibm.cos
  }
  depends_on = [time_sleep.wait_for_authorization_policy[0]]
  source     = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version    = "10.2.21"
  bucket_configs = [
    {
      bucket_name              = local.data_bucket_name
      kms_key_crn              = var.kms_encryption_enabled_buckets ? local.kms_key_crn : null
      kms_guid                 = var.kms_encryption_enabled_buckets ? local.existing_kms_guid : null
      kms_encryption_enabled   = var.kms_encryption_enabled_buckets
      region_location          = var.region
      resource_instance_id     = var.existing_cos_instance_crn
      management_endpoint_type = var.management_endpoint_type_for_buckets
      storage_class            = var.cloud_logs_cos_buckets_class
      force_delete             = true # If this is set to false, and the bucket contains data, the destroy will fail. Setting it to false on destroy has no impact, it has to be set on apply, so hence hard coding to true."
      activity_tracking = {
        read_data_events  = true
        write_data_events = true
        management_events = true
      }
      metrics_monitoring = {
        usage_metrics_enabled   = true
        request_metrics_enabled = true
        metrics_monitoring_crn  = var.existing_monitoring_crn
      }
    },
    {
      bucket_name                   = local.metrics_bucket_name
      kms_key_crn                   = var.kms_encryption_enabled_buckets ? local.kms_key_crn : null
      kms_guid                      = var.kms_encryption_enabled_buckets ? local.existing_kms_guid : null
      kms_encryption_enabled        = var.kms_encryption_enabled_buckets
      region_location               = var.region
      resource_instance_id          = var.existing_cos_instance_crn
      management_endpoint_type      = var.management_endpoint_type_for_buckets
      storage_class                 = var.cloud_logs_cos_buckets_class
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
        metrics_monitoring_crn  = var.existing_monitoring_crn
      }
    }
  ]
}

module "bucket_crns" {
  for_each = module.buckets.buckets
  source   = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version  = "1.2.0"
  crn      = each.value.bucket_id
}

data "ibm_iam_account_settings" "iam_account_settings" {
  count = local.create_cross_account_cos_auth_policy ? 1 : 0
}

resource "ibm_iam_authorization_policy" "cos_policy" {
  provider               = ibm.cos
  count                  = local.create_cross_account_cos_auth_policy ? length(module.buckets.bucket_configs) : 0
  source_service_account = data.ibm_iam_account_settings.iam_account_settings[0].account_id
  source_service_name    = "logs"
  roles                  = ["Writer"]
  description            = "Allow Cloud logs instances `Writer` access to the COS bucket with ID ${module.bucket_crns[module.buckets.bucket_configs[count.index].bucket_name].resource}, in the COS instance with ID ${module.existing_cos_instance_crn_parser.service_instance}."

  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = "cloud-object-storage"
  }

  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = module.existing_cos_instance_crn_parser.account_id
  }

  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = module.existing_cos_instance_crn_parser.service_instance
  }

  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "bucket"
  }

  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = module.bucket_crns[module.buckets.bucket_configs[count.index].bucket_name].resource
  }
}

resource "time_sleep" "wait_for_cos_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.cos_policy]
  count           = var.ibmcloud_cos_api_key != null && !var.skip_cloud_logs_cos_auth_policy ? length(module.buckets.bucket_configs) : 0
  create_duration = "30s"
}

module "existing_kms_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.2.0"
  crn     = var.existing_kms_instance_crn
}

module "existing_kms_key_crn_parser" {
  count   = var.existing_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.2.0"
  crn     = var.existing_kms_key_crn
}

# Create IAM Authorization Policy to allow COS to access KMS for the encryption key, if cross account KMS is passed in
resource "ibm_iam_authorization_policy" "cos_kms_policy" {
  provider                    = ibm.kms
  count                       = local.create_cross_account_auth_policy ? local.is_same_cross_account ? 0 : 1 : 0
  source_service_account      = module.existing_cos_instance_crn_parser.account_id
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = local.cos_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow the COS instance ${local.cos_instance_guid} to read the ${local.kms_service_name} key ${local.kms_key_id} from the instance ${local.existing_kms_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service_name
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.existing_kms_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on = [ibm_iam_authorization_policy.cos_kms_policy]
  count      = local.create_cross_account_auth_policy ? 1 : 0

  create_duration = "30s"
}

module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = local.use_kms_module ? 1 : 0
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "5.2.0"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name     = local.key_ring_name
      existing_key_ring = false
      keys = [
        {
          key_name                 = local.key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}
