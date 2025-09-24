########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key to deploy resources."
  sensitive   = true
}

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources. If not provided the default resource group will be used."
  default     = null
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and can not contain consecutive hyphens ('--'). Example: prod-0205-icl. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "provider_visibility" {
  type        = string
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "region" {
  type        = string
  description = "The region to provision all resources in. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/region) about how to select different regions for different services."
  default     = "us-south"
}

########################################################################################################################
# COS
########################################################################################################################

variable "ibmcloud_cos_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create Cloud Object Storage (COS) buckets. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the COS instance is in an account that's different from the one associated with the cloud logs resources. Do not set if the same account owns all the instances."
  sensitive   = true
  default     = null
}

variable "existing_cos_instance_crn" {
  type        = string
  description = "The CRN of an existing Object Storage instance."

  validation {
    condition     = var.existing_cos_instance_crn == null ? var.existing_cloud_logs_crn != null : true
    error_message = "A value must be passed for 'existing_cos_instance_crn' when creating a new instance."
  }
}

variable "cloud_logs_data_cos_bucket_name" {
  type        = string
  nullable    = true
  default     = "cloud-logs-logs-bucket"
  description = "The name of an to be given to a new bucket inside the existing Object Storage instance to use for IBM Cloud Logs. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "cloud_logs_metrics_cos_bucket_name" {
  type        = string
  nullable    = true
  default     = "cloud-logs-metrics-bucket"
  description = "The name of an to be given to a new bucket inside the existing Object Storage instance to use for IBM Cloud Logs. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "cloud_logs_cos_buckets_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned IBM Cloud Logs Object Storage buckets. Possible values: `standard` or `smart`. [Learn more](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-classes). Applies only if `existing_cloud_logs_crn` is not provided."
  validation {
    condition     = contains(["standard", "smart"], var.cloud_logs_cos_buckets_class)
    error_message = "Allowed values for cos_bucket_class are \"standard\" or \"smart\"."
  }
}

variable "management_endpoint_type_for_buckets" {
  description = "The type of endpoint for the IBM Terraform provider to use to manage Object Storage buckets. Possible values: `public`, `private`, `direct`. If you specify `private`, enable virtual routing and forwarding in your account, and the Terraform runtime must have access to the the IBM Cloud private network."
  type        = string
  default     = "direct"
  validation {
    condition     = contains(["public", "private", "direct"], var.management_endpoint_type_for_buckets)
    error_message = "The specified management_endpoint_type_for_buckets is not a valid selection!"
  }
}

variable "skip_cos_kms_iam_auth_policy" {
  type        = bool
  description = "Set to `true` to skip the creation of an IAM authorization policy that permits the Object Storage instance created to read the encryption key from the KMS instance. If set to false, pass in a value for the KMS instance in the `existing_kms_instance_crn` variable. If a value is specified for `ibmcloud_kms_api_key`, the policy is created in the KMS account. Applies only if `existing_cloud_logs_crn` is not provided."
  nullable    = false
  default     = false
}

variable "skip_cloud_logs_cos_auth_policy" {
  type        = bool
  description = "To skip creating an IAM authorization policy that allows the IBM Cloud logs to write to the Cloud Object Storage bucket, set this variable to `true`."
  default     = false
}

variable "existing_monitoring_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an IBM Cloud Monitoring instance to to send IBM Cloud Logs buckets metrics to. If no value passed, metrics are sent to the instance associated to the container's location unless otherwise specified in the Metrics Router service configuration. Applies only if `existing_cloud_logs_crn` is not provided."
}

########################################################################################################################
# KMS
########################################################################################################################

variable "kms_encryption_enabled_buckets" {
  description = "Set to true to enable KMS encryption on the Object Storage buckets created for the IBM Cloud Logs instance. When set to true, a value must be passed for either `existing_kms_key_crn` or `existing_kms_instance_crn` (to create a new key). Can not be set to true if passing a value for `existing_cloud_logs_crn`."
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = var.kms_encryption_enabled_buckets ? var.existing_cloud_logs_crn == null : true
    error_message = "'kms_encryption_enabled_buckets' should be false if passing a value for 'existing_cloud_logs_crn' as existing Cloud Logs instance will already have a bucket attached."
  }

  validation {
    condition     = var.existing_kms_instance_crn != null ? var.kms_encryption_enabled_buckets : true
    error_message = "If passing a value for 'existing_kms_instance_crn', you should set 'kms_encryption_enabled_buckets' to true."
  }

  validation {
    condition     = var.existing_kms_key_crn != null ? var.kms_encryption_enabled_buckets : true
    error_message = "If passing a value for 'existing_kms_key_crn', you should set 'kms_encryption_enabled_buckets' to true."
  }

  validation {
    condition     = var.kms_encryption_enabled_buckets ? ((var.existing_kms_key_crn != null || var.existing_kms_instance_crn != null) ? true : false) : true
    error_message = "Either 'existing_kms_key_crn' or 'existing_kms_instance_crn' is required if 'kms_encryption_enabled_buckets' is set to true."
  }
}

variable "existing_kms_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing KMS instance (Hyper Protect Crypto Services or Key Protect). Used to create a new KMS key unless an existing key is passed using the `existing_cloud_logs_cos_kms_key_crn` input. If the KMS instance is in different account you must also provide a value for `ibmcloud_kms_api_key`. A value should not be passed passing existing Cloud Logs instance using the `existing_cloud_logs_crn` input."

  validation {
    condition = anytrue([
      can(regex("^crn:(.*:){3}(kms|hs-crypto):(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_kms_instance_crn)),
      var.existing_kms_instance_crn == null,
    ])
    error_message = "The provided KMS instance CRN in the input 'existing_kms_instance_crn' in not valid."
  }

  validation {
    condition     = var.existing_kms_instance_crn != null ? var.existing_cloud_logs_crn == null : true
    error_message = "A value should not be passed for 'existing_kms_instance_crn' when passing an existing Cloud Logs instance using the 'existing_cloud_logs_crn' input."
  }
}

variable "existing_kms_key_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing KMS key to use to encrypt both of the Cloud Logs Object Storage buckets. If no value is set for this variable and bucket encryption is desired, specify a value for the `existing_kms_instance_crn` variable to create a key ring and key."

  validation {
    condition = anytrue([
      can(regex("^crn:(.*:){3}(kms|hs-crypto):(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:key:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.existing_kms_key_crn)),
      var.existing_kms_key_crn == null,
    ])
    error_message = "The provided KMS key CRN in the input 'existing_kms_key_crn' in not valid."
  }

  validation {
    condition     = var.existing_kms_key_crn != null ? var.existing_cloud_logs_crn == null : true
    error_message = "A value should not be passed for 'existing_kms_key_crn' when passing an existing Cloud Logs instance using the 'existing_cloud_logs_crn' input."
  }

  validation {
    condition     = var.existing_kms_key_crn != null ? var.existing_kms_instance_crn == null : true
    error_message = "A value should not be passed for 'existing_kms_instance_crn' when passing an existing key value using the 'existing_kms_key_crn' input."
  }

}

variable "kms_endpoint_type" {
  type        = string
  description = "The endpoint for communicating with the KMS instance. Possible values: `public`, `private.`"
  default     = "private"
  validation {
    condition     = can(regex("^(public|private)$", var.kms_endpoint_type))
    error_message = "The kms_endpoint_type value must be 'public' or 'private'."
  }
}

variable "cloud_logs_cos_key_ring_name" {
  type        = string
  default     = "cloud-logs-cos-key-ring"
  description = "The name for the key ring created for the key used for both of the Cloud Logs Object Storage buckets. Applies only if encryption is desired and if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "cloud_logs_cos_key_name" {
  type        = string
  default     = "cloud-logs-cos-key"
  description = "The name for the key created to encrypt both of the Cloud Logs Object Storage buckets. Applies only if encryption is desired and if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "ibmcloud_kms_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a root key and key ring in the key management service (KMS) instance. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the instance in `existing_kms_instance_crn` is in an account that's different from the Cloud Logs instance. Leave this input empty if the same account owns both instances."
  sensitive   = true
  default     = null

  validation {
    condition     = var.ibmcloud_kms_api_key != null ? var.existing_cloud_logs_crn == null : true
    error_message = "A value should not be passed for 'ibmcloud_kms_api_key' when passing an existing Cloud Logs instance using the 'existing_cloud_logs_crn' input."
  }
}

########################################################################################################################
# Cloud Logs
########################################################################################################################

variable "existing_cloud_logs_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing Cloud Logs instance. If not supplied, a new instance will be created."
}

variable "cloud_logs_instance_name" {
  type        = string
  description = "The name of the IBM Cloud Logs instance to create. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<instance_name>` format."
  default     = "cloud-logs"
}

variable "cloud_logs_resource_tags" {
  type        = list(string)
  description = "Tags associated with the IBM Cloud Logs instance (Optional, array of strings)."
  default     = []
}

variable "cloud_logs_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the IBM Cloud Logs instance created by the DA. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial."
  default     = []
}

variable "cloud_logs_retention_period" {
  type        = number
  description = "The number of days IBM Cloud Logs will retain the logs data in Priority insights. Allowed values: 7, 14, 30, 60, 90."
  default     = 7

  validation {
    condition     = contains([7, 14, 30, 60, 90], var.cloud_logs_retention_period)
    error_message = "Valid values 'cloud_logs_retention_period' are: 7, 14, 30, 60, 90"
  }
}

##############################################################################
# Event Notification
##############################################################################

variable "existing_event_notifications_instances" {
  type = list(object({
    crn                  = string
    integration_name     = optional(string)
    skip_iam_auth_policy = optional(bool, false)
  }))
  default     = []
  description = "List of Event Notifications instance details for routing critical events that occur in your IBM Cloud Logs. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-cloud-logs/tree/main/solutions/fully-configurable/DA-types.md#existing-event-notification-instances-)."
}

##############################################################################
# Logs Routing
##############################################################################

variable "logs_routing_tenant_regions" {
  type        = list(any)
  default     = []
  description = "Pass a list of regions to create a tenant for that is targeted to the Cloud Logs instance created by this module. To manage platform logs that are generated by IBM Cloud® services in a region of IBM Cloud, you must create a tenant in each region that you operate. Leave the list empty if you don't want to create any tenants. NOTE: You can only have 1 tenant per region in an account."
  nullable    = false
}

variable "skip_logs_routing_auth_policy" {
  description = "Whether to create an IAM authorization policy that permits the Logs Routing server 'Sender' access to the IBM Cloud Logs instance created by this Deployable Architecture."
  type        = bool
  default     = false
}

#############################################################################################################
# Logs Policies Configuration
#
# logs_policy_name -The name of the IBM Cloud Logs policy to create.
# logs_policy_description - Description of the IBM Cloud Logs policy to create.
# logs_policy_priority - Select priority to determine the pipeline for the logs. High (priority value) sent to 'Priority insights' (TCO pipeline), Medium to 'Analyze and alert', Low to 'Store and search', Blocked are not sent to any pipeline.
# application_rule - Define rules for matching applications to include in the policy configuration.
# subsystem_rule - Define subsystem rules for matching applications to include in the policy configuration.
# log_rules - Define the log severities to include in the policy configuration.
# archive_retention - Define archive retention.
##############################################################################################################

variable "logs_policies" {
  type = list(object({
    logs_policy_name        = string
    logs_policy_description = optional(string, null)
    logs_policy_priority    = string
    application_rule = optional(list(object({
      name         = string
      rule_type_id = string
    })))
    subsystem_rule = optional(list(object({
      name         = string
      rule_type_id = string
    })))
    log_rules = optional(list(object({
      severities = list(string)
    })))
    archive_retention = optional(list(object({
      id = string
    })))
  }))
  description = "Configuration of Cloud Logs policies. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-cloud-logs/tree/main/solutions/fully-configurable/DA-types.md)."
  default     = []

  validation {
    condition     = alltrue([for config in var.logs_policies : (length(config.logs_policy_name) <= 4096 ? true : false)])
    error_message = "Maximum length of logs_policy_name allowed is 4096 chars."
  }

  validation {
    condition     = alltrue([for config in var.logs_policies : contains(["type_unspecified", "type_block", "type_low", "type_medium", "type_high"], config.logs_policy_priority)])
    error_message = "The specified priority for logs policy is not a valid selection. Allowed values are: type_unspecified, type_block, type_low, type_medium, type_high."
  }

  validation {
    condition = alltrue(
      [for config in var.logs_policies :
        (config.application_rule != null ?
          (alltrue([for rule in config.application_rule :
          contains(["unspecified", "is", "is_not", "start_with", "includes"], rule.rule_type_id)]))
        : true)
    ])
    error_message = "Identifier of application_rule 'rule_type_id' is not a valid selection. Allowed values are: unspecified, is, is_not, start_with, includes."
  }

  validation {
    condition = alltrue(
      [for config in var.logs_policies :
        (config.application_rule != null ?
          (alltrue([for rule in config.application_rule :
          can(regex("^[\\p{L}\\p{N}\\p{P}\\p{Z}\\p{S}\\p{M}]+$", rule.name)) && length(rule.name) <= 4096 && length(rule.name) > 1]))
        : true)
    ])
    error_message = "The name of the application_rule does not meet the required criteria."
  }

  validation {
    condition = alltrue(
      [for config in var.logs_policies :
        (config.log_rules != null && length(config.log_rules) > 0 ? true : false)
    ])
    error_message = "The log_rules can not be empty and must contain at least 1 item."
  }

  validation {
    condition = alltrue(
      [for config in var.logs_policies :
        (config.log_rules != null ?
          (alltrue([for rule in config.log_rules :
            alltrue([for severity in rule["severities"] :
          contains(["unspecified", "debug", "verbose", "info", "warning", "error", "critical"], severity)])]))
          : true
    )])
    error_message = "The 'severities' of log_rules is not a valid selection. Allowed values are: unspecified, debug, verbose, info, warning, error, critical."
  }

  validation {
    condition = alltrue(
      [for config in var.logs_policies :
        (config.subsystem_rule != null ?
          (alltrue([for rule in config.subsystem_rule :
          contains(["unspecified", "is", "is_not", "start_with", "includes"], rule.rule_type_id)]))
          : true
    )])
    error_message = "Identifier of subsystem_rule 'rule_type_id' is not a valid selection. Allowed values are: unspecified, is, is_not, start_with, includes."
  }

  validation {
    condition = alltrue(
      [for config in var.logs_policies :
        (config.subsystem_rule != null ?
          (alltrue([for rule in config.subsystem_rule :
          can(regex("^[\\p{L}\\p{N}\\p{P}\\p{Z}\\p{S}\\p{M}]+$", rule.name)) && length(rule.name) <= 4096 && length(rule.name) > 1]))
        : true)
    ])
    error_message = "The name of the subsystem_rule does not meet the required criteria."
  }

  validation {
    condition = alltrue(
      [for config in var.logs_policies :
        (config.archive_retention != null ?
          (alltrue(
            [for rule in config.archive_retention : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", rule.id))]
          )) : true
    )])
    error_message = "The id of the archive_retention does not meet the required criteria."
  }
}

##############################################################
# Context-based restriction (CBR)
##############################################################

variable "cloud_logs_cbr_rules" {
  type = list(object({
    description = string
    account_id  = string
    rule_contexts = list(object({
      attributes = optional(list(object({
        name  = string
        value = string
    }))) }))
    enforcement_mode = string
    operations = optional(list(object({
      api_types = list(object({
        api_type_id = string
      }))
    })))
  }))
  description = "(Optional, list) List of context-based restrictions rules to create. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-cloud-logs/tree/main/solutions/fully-configurable/DA-types.md)."
  default     = []
}
