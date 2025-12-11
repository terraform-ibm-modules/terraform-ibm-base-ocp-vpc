variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are `public`, `private`, or `public-and-private`."
  }
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to null or an empty string."

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
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "region" {
  type        = string
  description = "The region to provision all resources in."
  default     = "us-south"
  nullable    = false
}

variable "resource_group_id" {
  type        = string
  description = "The ID of an existing IBM Cloud resource group where the cluster is grouped."
}

##############################################################
# KMS Related
##############################################################
variable "kms_encryption_enabled_cluster" {
  description = "Set to true to enable KMS encryption for the cluster's Object Storage bucket. When set to true, a value must be passed for either `existing_cluster_kms_key_crn` or `existing_kms_instance_crn`."
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = var.existing_kms_instance_crn != null ? var.kms_encryption_enabled_cluster : true
    error_message = "If passing a value for 'existing_kms_instance_crn', you should set 'kms_encryption_enabled_cluster' to true."
  }

  validation {
    condition     = var.existing_cluster_kms_key_crn != null ? var.kms_encryption_enabled_cluster : true
    error_message = "If passing a value for 'existing_cluster_kms_key_crn', you should set 'kms_encryption_enabled_cluster' to true."
  }
}

variable "existing_kms_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing KMS instance (Hyper Protect Crypto Services or Key Protect)."

  validation {
    condition = anytrue([
      can(regex("^crn:(.*:){3}(kms|hs-crypto):(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_kms_instance_crn)),
      var.existing_kms_instance_crn == null,
    ])
    error_message = "The provided KMS instance CRN in the input 'existing_kms_instance_crn' in not valid."
  }
}

variable "existing_cluster_kms_key_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing KMS key to use for encrypting the Object Storage of the Cluster. If no value is set for this variable, specify a value for `existing_kms_instance_crn` variable to create a key ring and key."

  validation {
    condition = anytrue([
      can(regex("^crn:(.*:){3}(kms|hs-crypto):(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:key:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.existing_cluster_kms_key_crn)),
      var.existing_cluster_kms_key_crn == null,
    ])
    error_message = "The provided KMS key CRN in the input 'existing_cluster_kms_key_crn' in not valid."
  }

  validation {
    condition     = var.existing_cluster_kms_key_crn != null ? var.existing_kms_instance_crn == null : true
    error_message = "A value should not be passed for 'existing_kms_instance_crn' when passing an existing key value using the 'existing_cluster_kms_key_crn' input."
  }

}

variable "kms_endpoint_type" {
  type        = string
  description = "The endpoint for communicating with the KMS instance. Possible values: `public`, `private`. Applies only if `kms_encryption_enabled_cluster` is true"
  default     = "private"
  nullable    = false
  validation {
    condition     = can(regex("^(public|private)$", var.kms_endpoint_type))
    error_message = "The kms_endpoint_type value must be 'public' or 'private'."
  }
}

variable "cluster_kms_key_ring_name" {
  type        = string
  default     = "cluster-key-ring"
  description = "The name of the key ring to be created for the cluster's Object Storage bucket encryption key. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "cluster_kms_key_name" {
  type        = string
  default     = "cluster-key"
  description = "The name of the key to be created for the cluster's Object Storage bucket encryption. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "kms_encryption_enabled_boot_volume" {
  type        = bool
  description = "Set this to true to control the encryption keys used to encrypt the data that for the block storage volumes for VPC. If set to false, the data is encrypted by using randomly generated keys. For more info on encrypting block storage volumes, see https://cloud.ibm.com/docs/vpc?topic=vpc-creating-instances-byok"
  default     = false
  nullable    = false

  validation {
    condition     = var.existing_kms_instance_crn != null ? var.kms_encryption_enabled_boot_volume || var.kms_encryption_enabled_cluster : true
    error_message = "If passing a value for 'existing_kms_instance_crn', you should set 'kms_encryption_enabled_boot_volume' to true."
  }

  validation {
    condition     = var.existing_boot_volume_kms_key_crn != null ? var.kms_encryption_enabled_boot_volume : true
    error_message = "If passing a value for 'existing_boot_volume_kms_key_crn', you should set 'kms_encryption_enabled_boot_volume' to true."
  }
}

variable "existing_boot_volume_kms_key_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing KMS key to use to encrypt the the block storage volumes for VPC. If no value is set for this variable, specify a value for either the `existing_kms_instance_crn` variable to create a key ring and key."

  validation {
    condition = anytrue([
      can(regex("^crn:(.*:){3}(kms|hs-crypto):(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:key:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.existing_boot_volume_kms_key_crn)),
      var.existing_boot_volume_kms_key_crn == null,
    ])
    error_message = "The provided KMS key CRN in the input 'existing_boot_volume_kms_key_crn' in not valid."
  }
}

variable "boot_volume_kms_key_ring_name" {
  type        = string
  default     = "boot-volume-key-ring"
  description = "The name for the key ring created for the block storage volumes key. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "boot_volume_kms_key_name" {
  type        = string
  default     = "boot-volume-key"
  description = "The name for the key created for the block storage volumes. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "kms_instance_name" {
  type        = string
  description = "The name to give the Key Protect instance that that is created by this module. Only used if 'create_key_protect_instance' is set to `true`."
  default     = "key-protect"
}

variable "kms_plan" {
  type        = string
  description = "Plan for the Key Protect instance. Supported values are 'tiered-pricing' and 'cross-region-resiliency'. Only used if 'create_key_protect_instance' is set to `true`."
  default     = "tiered-pricing"
  # validation performed in terraform-ibm-key-protect module
}

variable "rotation_enabled" {
  type        = bool
  description = "If set to `true`, a rotation policy is enabled on the Key Protect instance. Only used if 'create_key_protect_instance' is set to `true`."
  default     = true
}

variable "rotation_interval_month" {
  type        = number
  description = "Specifies how often keys are rotated in months. Value must be between `1` and `12` inclusive. Only used if 'create_key_protect_instance' is set to `true`."
  default     = 1
}

variable "dual_auth_delete_enabled" {
  type        = bool
  description = "If set to `true`, a dual authorization policy is enabled on the Key Protect instance. After the dual authorization policy is set on the instance, it cannot be reverted. An instance with dual authorization policy enabled cannot be destroyed by using Terraform. Only used if 'create_key_protect_instance' is set to `true`."
  default     = false
}

variable "enable_metrics" {
  type        = bool
  description = "Set to `true` to enable metrics on the Key Protect instance. Only used if 'create_key_protect_instance' is set to `true`. In order to view metrics, you need an IBM Cloud Monitoring (Sysdig) instance that is located in the same region as the Key Protect instance. After you provision a Monitoring instance, enable platform metrics to monitor your Key Protect instance."
  default     = true
}

variable "key_create_import_access_enabled" {
  type        = bool
  description = "If set to `true`, a key create and import access policy is enabled on the instance of Key Protect. Only used if 'create_key_protect_instance' is set to `true`."
  default     = true
}

variable "key_protect_allowed_network" {
  type        = string
  description = "Allowed network types for the Key Protect instance. Possible values are 'private-only', or 'public-and-private'. Only used if 'create_key_protect_instance' is set to `true`."
  default     = "private-only"
  validation {
    condition     = can(regex("private-only|public-and-private", var.key_protect_allowed_network))
    error_message = "The `key_protect_allowed_network` value must be 'private-only' or 'public-and-private'."
  }
}

variable "kms_resource_tags" {
  type        = list(string)
  description = "Optional list of tags to add to the Key Protect instance. Only used if 'create_key_protect_instance' is set to `true`."
  default     = []
}

variable "kms_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Key Protect instance. Only used if 'create_key_protect_instance' is set to `true`."
  default     = []
}

variable "kms_cbr_rules" {
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
  description = "The context-based restrictions rule to create. Only one rule is allowed."
  default     = []
  # Validation happens in the rule module
  # NOTE: Context-based restriction rules applies to Key Protect instances only and is not supported by Hyper Protect Crypto Services (HPCS) instances

  validation {
    condition     = var.existing_kms_instance_crn == null ? true : length(regexall(".*hscrypto.*", var.existing_kms_instance_crn)) > 0 ? length(var.kms_cbr_rules) == 0 : true
    error_message = "When passing a Hyper Protect Crypto Services (HPCS) instance as a value for `existing_kms_instance_crn` you cannot provide `kms_cbr_rules`. Context-based restrictions are not supported by HPCS instances. For more information, go to [services that integrate with context-based restrictions](https://cloud.ibm.com/docs/account?topic=account-context-restrictions-whatis#cbr-adopters)."
  }
  validation {
    condition     = length(var.kms_cbr_rules) <= 1
    error_message = "Only one CBR rule is allowed."
  }
}

########################################################################################################################
# Event Notifications
########################################################################################################################

variable "event_notifications_instance_name" {
  type        = string
  description = "The name of the Event Notifications instance that is created by this solution. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "event-notifications"
}

variable "en_service_plan" {
  type        = string
  description = "The pricing plan of the Event Notifications instance. Possible values: `Lite`, `Standard`."
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.en_service_plan)
    error_message = "The specified pricing plan is not available. The following plans are supported: `Lite`, `Standard`"
  }
}

variable "en_service_endpoints" {
  type        = string
  description = "Specify whether you want to enable public, private, or both public and private service endpoints. Possible values: `public`, `private`, `public-and-private`."
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.en_service_endpoints)
    error_message = "The specified service endpoint is not supported. The following endpoint options are supported: `public`, `private`, `public-and-private`"
  }
}

variable "en_resource_tags" {
  type        = list(string)
  description = "The list of tags to add to the Event Notifications instance."
  default     = []
}

variable "en_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Event Notifications instance created by the solution. For more information, [see here](https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial)."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.en_access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\". For more information, [see here](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limit)."
  }
}

variable "en_service_credential_names" {
  type        = map(string)
  description = "A mapping of names and associated roles for service credentials that you want to create for the Event Notifications instance. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/blob/main/solutions/fully-configurable/DA-types.md#service-credentials-)."
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.en_service_credential_names : contains(["Manager", "Writer", "Reader", "Event Source Manager", "Channel Editor", "Event Notification Publisher", "Status Reporter", "Device Manager", "Email Sender", "Custom Email Status Reporter"], role)])
    error_message = "The specified service credential role is not valid. The following values are valid for service credential roles: 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', 'Custom Email Status Reporter'"
  }
}

variable "kms_endpoint_url" {
  type        = string
  description = "The KMS endpoint URL to use when you configure KMS encryption. When set to true, a value must be passed for either `existing_kms_root_key_crn` or `existing_kms_instance_crn` (to create a new key). The Hyper Protect Crypto Services endpoint URL format is `https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>` and the Key Protect endpoint URL format is `https://<REGION>.kms.cloud.ibm.com`. Not required if passing an existing instance using the `existing_event_notifications_instance_crn` input."
  default     = null
}

variable "skip_event_notifications_kms_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits the Event Notifications instance to read the encryption key from the KMS instance. If a value is specified for `ibmcloud_kms_api_key`, the policy is created in the KMS account."
  default     = false
}

variable "enable_collecting_failed_events" {
  type        = bool
  description = "Set to true to enable Cloud Object Storage integration. If enabled, you must also provide a Cloud Object Storage instance (for storing failed events) using the `existing_cos_instance_crn` variable. For more information, [see here](https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-en-cfe-integrations)."
  default     = true
}

variable "en_cos_bucket_name" {
  type        = string
  description = "The name to use when creating the Object Storage bucket for the storage of failed delivery events. Bucket names are globally unique. If `add_bucket_name_suffix` is set to `true`, a random 4 character string is added to this name to help ensure that the bucket name is unique. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "base-event-notifications-bucket"
}

variable "en_cos_bucket_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Cloud Object Storage bucket created by the solution. For more information, [see here](https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial)."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.en_cos_bucket_access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\". For more information, [see here](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits)."
  }
}

variable "skip_event_notifications_secrets_manager_auth_policy" {
  type        = bool
  default     = false
  description = "Whether an IAM authorization policy is created for Secrets Manager instance to create a service credential secrets for Event Notification.If set to false, the Secrets Manager instance passed by the user is granted the Key Manager access to the Event Notifications instance created by the Deployable Architecture. Set to `true` to use an existing policy. The value of this is ignored if any value for 'existing_secrets_manager_crn' is not passed."
}

variable "en_cbr_rules" {
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
  description = "The list of context-based restrictions rules to create. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-cbr_rules.md)."
  default     = []
}

variable "en_service_credential_secrets" { # pragma: allowlist secret
  type = list(object({
    secret_group_name        = string                                      # pragma: allowlist secret
    secret_group_description = optional(string)                            # pragma: allowlist secret
    existing_secret_group    = optional(bool)                              # pragma: allowlist secret
    service_credentials = list(object({                                    # pragma: allowlist secret
      secret_name                                 = string                 # pragma: allowlist secret
      service_credentials_source_service_role_crn = string                 # pragma: allowlist secret
      secret_labels                               = optional(list(string)) # pragma: allowlist secret
      secret_auto_rotation                        = optional(bool)         # pragma: allowlist secret
      secret_auto_rotation_unit                   = optional(string)       # pragma: allowlist secret
      secret_auto_rotation_interval               = optional(number)       # pragma: allowlist secret
      service_credentials_ttl                     = optional(string)       # pragma: allowlist secret
      service_credential_secret_description       = optional(string)       # pragma: allowlist secret

    }))
  }))
  default     = []
  description = "Service credential secrets configuration for Event Notification. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-types.md#service-credential-secrets)."

  validation {
    # Service roles CRNs can be found at https://cloud.ibm.com/iam/roles, select Event Notifications and select the role
    condition = alltrue([
      for group in var.en_service_credential_secrets : alltrue([
        # crn:v?:bluemix; two non-empty segments; three possibly empty segments; :serviceRole or role: non-empty segment
        for credential in group.service_credentials : can(regex("^crn:v[0-9]:bluemix(:..*){2}(:.*){3}:(serviceRole|role):..*$", credential.service_credentials_source_service_role_crn))
      ])
    ])
    error_message = "Provided value of `service_credentials_source_service_role_crn` is not valid. Refer [this](https://cloud.ibm.com/iam/roles) for allowed role/values."
  }
  validation {
    condition     = length(var.en_service_credential_secrets) > 0 ? var.existing_secrets_manager_crn != null : true
    error_message = "'existing_secrets_manager_crn' is required when adding service credentials with the 'service_credential_secrets' input."
  }

}

variable "skip_event_notifications_cos_auth_policy" {
  type        = bool
  description = "Set to `true` to skip the creation of an IAM authorization policy that permits the Event Notifications instance `Object Writer` and `Reader` access to the given Object Storage bucket. Set to `true` to use an existing policy."
  default     = false
}

variable "event_notifications_endpoint_url" {
  type        = string
  description = "The URL of the Event Notifications service endpoint to use for notifying configuration changes. For more information on the endpoint URL for Event Notifications, go to [Service endpoints](https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-en-regions-endpoints#en-service-endpoints). It is required if `enable_event_notifications` is set to true."
  default     = null
}

##############################################################
# Secrets Manager
##############################################################

variable "secrets_manager_instance_name" {
  type        = string
  description = "The name to give the Secrets Manager instance provisioned by this solution. If a prefix input variable is specified, it is added to the value in the `<prefix>-value` format. Applies only if `existing_secrets_manager_crn` is not provided."
  default     = "secrets-manager"
}

variable "existing_secrets_manager_crn" {
  type        = string
  description = "The CRN of an existing Secrets Manager instance. If not supplied, a new instance is created."
  default     = null
}

variable "secrets_manager_service_plan" {
  type        = string
  description = "The pricing plan to use when provisioning a Secrets Manager instance. Possible values: `standard`, `trial`. You can create only one Trial instance of Secrets Manager per account. Before you can create a new Trial instance, you must delete the existing Trial instance and its reclamation."
  default     = "standard"
  validation {
    condition     = var.existing_secrets_manager_crn == null ? contains(["standard", "trial"], var.secrets_manager_service_plan) : true
    error_message = "Only 'standard' and 'trial' are allowed values for 'secrets_manager_service_plan'. Applies only if not providing a value for the 'existing_secrets_manager_crn' input."
  }
}

variable "skip_secrets_manager_iam_auth_policy" {
  type        = bool
  description = "Whether to skip the creation of the IAM authorization policies required to enable the IAM credentials engine (if you are using an existing Secrets Manager instance, attempting to re-create can cause conflicts if the policies already exist). If set to false, policies will be created that grants the Secrets Manager instance 'Operator' access to the IAM identity service, and 'Groups Service Member Manage' access to the IAM groups service."
  default     = false
}

variable "secrets_manager_resource_tags" {
  type        = list(string)
  description = "The list of resource tags you want to associate with your Secrets Manager instance. Applies only if `existing_secrets_manager_crn` is not provided."
  default     = []
}

variable "secrets_manager_endpoint_type" {
  type        = string
  description = "The type of endpoint (public or private) to connect to the Secrets Manager API. The Terraform provider uses this endpoint type to interact with the Secrets Manager API and configure Event Notifications."
  default     = "private"
  validation {
    condition     = contains(["public", "private"], var.secrets_manager_endpoint_type)
    error_message = "The specified service endpoint is not a valid selection!"
  }
}

variable "secrets_manager_allowed_network" {
  type        = string
  description = "The types of service endpoints to set on the Secrets Manager instance. Possible values are `private-only` or `public-and-private`."
  default     = "private-only"
  validation {
    condition     = contains(["private-only", "public-and-private"], var.secrets_manager_allowed_network)
    error_message = "The specified allowed_network is not a valid selection!"
  }
}

variable "skip_secrets_manager_kms_iam_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all Secrets Manager instances in the resource group to read the encryption key from the KMS instance. If set to false, pass in a value for the KMS instance in the `existing_kms_instance_crn` variable."
  default     = false
}

variable "secret_groups" {
  type = list(object({
    secret_group_name        = string
    secret_group_description = optional(string)
    create_access_group      = optional(bool, true)
    access_group_name        = optional(string)
    access_group_roles       = optional(list(string), ["SecretsReader"])
    access_group_tags        = optional(list(string))
  }))
  description = "Secret Manager secret group and access group configurations. If a prefix input variable is specified, it is added to the `access_group_name` value in the `<prefix>-value` format. If you do not wish to create any groups, set the value to `[]`."
  nullable    = false
  default = [
    {
      secret_group_name        = "General"
      secret_group_description = "A general purpose secrets group with an associated access group which has a secrets reader role"
      create_access_group      = true
      access_group_name        = "general-secrets-group-access-group"
      access_group_roles       = ["SecretsReader"]
    }
  ]
  validation {
    error_message = "The name of the secret group cannot be null or empty string."
    condition = length([
      for group in var.secret_groups :
      true if(group.secret_group_name == "" || group.secret_group_name == null)
    ]) == 0
  }
  validation {
    error_message = "When creating an access group, a list of roles must be specified."
    condition = length([
      for group in var.secret_groups :
      true if(group.create_access_group && group.access_group_roles == null)
    ]) == 0
  }
}

variable "secrets_manager_cbr_rules" {
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
  description = "(Optional, list) List of CBR rules to create."
  default     = []
  # Validation happens in the rule module
}

########################################################################################################################
# Event Notifications
########################################################################################################################

variable "existing_event_notifications_instance_crn" {
  type        = string
  description = "The CRN of the Event Notifications service used to enable lifecycle notifications for your Secrets Manager instance."
  default     = null
}

variable "skip_secrets_manager_event_notifications_iam_auth_policy" {
  type        = bool
  description = "If set to true, this skips the creation of a service to service authorization from Secrets Manager to Event Notifications. If false, the service to service authorization is created."
  default     = false
}

variable "event_notifications_email_list" {
  type        = list(string)
  description = "The list of email address to target out when Secrets Manager triggers an event"
  default     = []
}

variable "event_notifications_from_email" {
  type        = string
  description = "The email address used to send any Secrets Manager event coming via Event Notifications"
  default     = "compliancealert@ibm.com"
}

variable "event_notifications_reply_to_email" {
  type        = string
  description = "The email address specified in the 'reply_to' section for any Secret Manager event coming via Event Notifications"
  default     = "no-reply@ibm.com"
}

##############################################################
# COS
##############################################################

variable "existing_cos_instance_crn" {
  type        = string
  description = "The CRN of an existing Object Storage instance."
  default     = null
}

variable "cos_instance_name" {
  description = "The name for the IBM Cloud Object Storage instance provisioned by this solution. If a value is passed for `prefix`, the instance will be named with the prefix value in the format of `<prefix>-value`."
  type        = string
  default     = "cos-instance"
}

variable "cos_instance_plan" {
  description = "The plan to use when Object Storage instances are created."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "cos-one-rate-plan"], var.cos_instance_plan)
    error_message = "The specified plan is not a valid selection!"
  }
}

variable "cos_instance_resource_tags" {
  description = "A list of resource tags to apply to the Object Storage instance."
  type        = list(string)
  default     = []
}

variable "cos_instance_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Object Storage instance created by the module."
  default     = []
}

variable "skip_secrets_manager_cos_iam_auth_policy" {
  type        = bool
  default     = false
  description = "Whether an IAM authorization policy is created for Secrets Manager instance to create a service credential secrets for Cloud Object Storage. Set to `true` to use an existing policy."
}

variable "service_cred" { # pragma: allowlist secret
  type = list(object({
    secret_group_name        = string                                      # pragma: allowlist secret
    secret_group_description = optional(string)                            # pragma: allowlist secret
    existing_secret_group    = optional(bool)                              # pragma: allowlist secret
    service_credentials = list(object({                                    # pragma: allowlist secret
      secret_name                                 = string                 # pragma: allowlist secret
      service_credentials_source_service_role_crn = string                 # pragma: allowlist secret
      secret_labels                               = optional(list(string)) # pragma: allowlist secret
      secret_auto_rotation                        = optional(bool)         # pragma: allowlist secret
      secret_auto_rotation_unit                   = optional(string)       # pragma: allowlist secret
      secret_auto_rotation_interval               = optional(number)       # pragma: allowlist secret
      service_credentials_ttl                     = optional(string)       # pragma: allowlist secret
      service_credential_secret_description       = optional(string)       # pragma: allowlist secret

    }))
  }))
  default     = []
  description = "Service configuration for COS."

  validation {
    # Service roles CRNs can be found at https://cloud.ibm.com/iam/roles, select Cloud Object Storage and select the role
    condition = alltrue([
      for group in var.service_cred : alltrue([
        # crn:v?:bluemix; two non-empty segments; three possibly empty segments; :serviceRole or role: non-empty segment
        for credential in group.service_credentials : can(regex("^crn:v[0-9]:bluemix(:..*){2}(:.*){3}:(serviceRole|role):..*$", credential.service_credentials_source_service_role_crn))
      ])
    ])
    error_message = "service_credentials_source_service_role_crn must be a serviceRole CRN. See https://cloud.ibm.com/iam/roles"
  }

  validation {
    condition     = length(var.service_cred) > 0 ? var.existing_secrets_manager_crn != null : true
    error_message = "When passing a value for 'service_credential', a value must be passed for 'existing_secrets_manager_crn'."
  }
}

variable "cos_instance_cbr_rules" {
  type = list(object({
    description = string
    account_id  = string
    rule_contexts = list(object({
      attributes = optional(list(object({
        name  = string
        value = string
    }))) }))
    enforcement_mode = string
    tags = optional(list(object({
      name  = string
      value = string
    })), [])
    operations = optional(list(object({
      api_types = list(object({
        api_type_id = string
      }))
    })))
  }))
  description = "The list of context-based restriction rules to create for the instance."
  default     = []
  # Validation happens in the rule module
}

########################################################################################################################
# Cloud Monitoring
########################################################################################################################

variable "existing_cloud_monitoring_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing Cloud Monitoring instance. If not supplied, a new instance will be created."
}

variable "cloud_monitoring_instance_name" {
  type        = string
  description = "The name of the IBM Cloud Monitoring instance to create. If the prefix variable is passed, the name of the instance is prefixed to the value in the `<prefix>-value` format."
  default     = "cloud-monitoring"
}

variable "cloud_monitoring_resource_tags" {
  type        = list(string)
  description = "Tags associated with the IBM Cloud Monitoring instance (Optional, array of strings)."
  default     = []
}

variable "cloud_monitoring_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the IBM Cloud Monitoring instance created by the DA. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial."
  default     = []
}

variable "disable_access_key_creation" {
  type        = bool
  description = "When set to true, disables the creation of a default manager access key which is required by agents to ingest metrics."
  default     = false
}

variable "cloud_monitoring_resource_keys" {
  description = "A list of maps representing resource keys to create for the IBM Cloud Monitoring instance. Each entry defines a single resource key. Use this list to manage custom keys and handle key rotation."
  type = list(object({
    name                      = string
    generate_hmac_credentials = optional(bool, false) # pragma: allowlist secret
    role                      = optional(string, "Manager")
    service_id_crn            = optional(string, null)
  }))
  default = []
}

variable "cloud_monitoring_plan" {
  type        = string
  description = "The IBM Cloud Monitoring plan to provision. Available values are `lite` and `graduated-tier` and graduated-tier-sysdig-secure-plus-monitor (available in region eu-fr2 only)."
  default     = "graduated-tier"

  validation {
    condition     = can(regex("^lite$|^graduated-tier$|^graduated-tier-sysdig-secure-plus-monitor$", var.cloud_monitoring_plan))
    error_message = "The plan value must be one of the following: lite, graduated-tier and graduated-tier-sysdig-secure-plus-monitor (available in region eu-fr2 only)."
  }

  validation {
    condition     = (var.cloud_monitoring_plan != "graduated-tier-sysdig-secure-plus-monitor") || var.region == "eu-fr2"
    error_message = "When cloud_monitoring_plan is graduated-tier-sysdig-secure-plus-monitor region should be set to eu-fr2."
  }
}

variable "enable_platform_metrics" {
  type        = bool
  description = "When set to `true`, the IBM Cloud Monitoring instance collects the platform metrics."
  default     = false
}

########################################################################################################################
# Metrics Routing
########################################################################################################################

variable "metrics_routing_target_name" {
  type        = string
  description = "The name of the IBM Cloud Metrics Routing target where metrics are collected. If the prefix variable is passed, the name of the target is prefixed to the value in the `<prefix>-value` format."
  default     = "cloud-monitoring-target"
}

variable "metrics_routing_route_name" {
  type        = string
  description = "The name of the IBM Cloud Metrics Routing route for the default route that indicate what metrics are routed in a region and where to store them. If the prefix variable is passed, the name of the target is prefixed to the value in the `<prefix>-value` format."
  default     = "metrics-routing-route"
}

variable "enable_metrics_routing_to_cloud_monitoring" {
  type        = bool
  description = "Whether to enable metrics routing from IBM Cloud Metric Routing to Cloud Monitoring."
  default     = true
}

variable "enable_primary_metadata_region" {
  type        = bool
  description = "When set to `true`, sets `primary_metadata_region` to `region`, storing Metrics Router metadata in that region. When `false`, no region is set and the default global region is used. For new accounts, creating targets and routes will fail until primary_metadata_region is set, so it is recommended to default enable_primary_metadata_region to true."
  default     = true
}

variable "metrics_router_routes" {
  type = list(object({
    name = string
    rules = list(object({
      action = string
      targets = list(object({
        id = string
      }))
      inclusion_filters = list(object({
        operand  = string
        operator = string
        values   = list(string)
      }))
    }))
  }))
  default     = []
  description = "Routes for IBM Cloud Metrics Routing."
}

variable "cloud_monitoring_cbr_rules" {
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
  description = "The list of context-based restriction rules to create for the instance."
  default     = []
  # Validation happens in the rule module
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

variable "existing_event_notifications_instances" {
  type = list(object({
    crn                  = string
    integration_name     = optional(string)
    skip_iam_auth_policy = optional(bool, false)
  }))
  default     = []
  description = "List of Event Notifications instance details for routing critical events that occur in your IBM Cloud Logs."
}

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
  description = "(Optional, list) List of context-based restrictions rules to create."
  default     = []
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

variable "skip_cloud_logs_cos_auth_policy" {
  type        = bool
  description = "To skip creating an IAM authorization policy that allows the IBM Cloud logs to write to the Cloud Object Storage bucket, set this variable to `true`."
  default     = false
}



variable "kms_encryption_enabled_buckets" {
  description = "Set to true to enable KMS encryption on the Object Storage buckets created for the IBM Cloud Logs instance. When set to true, a value must be passed for either `existing_cluster_kms_key_crn` or `existing_kms_instance_crn` (to create a new key). Can not be set to true if passing a value for `existing_cloud_logs_crn`."
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
    condition     = var.existing_cluster_kms_key_crn != null ? var.kms_encryption_enabled_buckets : true
    error_message = "If passing a value for 'existing_cluster_kms_key_crn', you should set 'kms_encryption_enabled_buckets' to true."
  }

  validation {
    condition     = var.kms_encryption_enabled_buckets ? ((var.existing_cluster_kms_key_crn != null || var.existing_kms_instance_crn != null) ? true : false) : true
    error_message = "Either 'existing_cluster_kms_key_crn' or 'existing_kms_instance_crn' is required if 'kms_encryption_enabled_buckets' is set to true."
  }
}

variable "append_random_bucket_name_suffix" {
  type        = bool
  description = "Append random generated suffix (4 characters long) to the newly provisioned IBM Cloud Logs Object Storage bucket names."
  default     = true
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

variable "cos_buckets_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned IBM Cloud Logs Object Storage buckets. Possible values: `standard` or `smart`. Applies only if `existing_cloud_logs_crn` is not provided."
  validation {
    condition     = contains(["standard", "smart"], var.cos_buckets_class)
    error_message = "Allowed values for cos_bucket_class are \"standard\" or \"smart\"."
  }
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
  description = "Configuration of Cloud Logs policies."
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

##############################################################################
# Activity Tracker Event Routing
##############################################################################

variable "enable_activity_tracker_event_routing_to_cos_bucket" {
  type        = bool
  description = "When set to `true`, you must provide a value for `existing_cos_instance_crn` to enable event routing from Activity Tracker to a Object Storage bucket."
  default     = true

  validation {
    condition     = var.enable_activity_tracker_event_routing_to_cos_bucket || var.enable_activity_tracker_event_routing_to_cloud_logs
    error_message = "At least one of 'enable_activity_tracker_event_routing_to_cos_bucket' or 'enable_activity_tracker_event_routing_to_cloud_logs' must be true to route audit events to COS bucket or Cloud Logs instance."
  }

}

variable "activity_tracker_cos_target_bucket_name" {
  type        = string
  default     = "at-events-cos-bucket"
  description = "The name of the Cloud Object Storage bucket to create for the Cloud Object Storage target to store AT events. Cloud Object Storage bucket names are globally unique. If the `add_bucket_name_suffix` variable is set to `true`, 4 random characters are added to this name to ensure that the name of the bucket is globally unique. If the prefix input variable is passed, the name of the instance is prefixed to the value in the `<prefix>-value` format."
}

variable "existing_activity_tracker_cos_target_bucket_name" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing bucket within the Cloud Object Storage instance in which to store IBM Cloud Activity Tracker Event Routing. If an existing Cloud Object Storage bucket is not specified, a bucket is created."
}

variable "existing_activity_tracker_cos_target_bucket_endpoint" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing Cloud Object Storage bucket endpoint to use for setting up IBM Cloud Activity Tracker Event Routing. If an existing endpoint is not specified, the endpoint of the new Cloud Object Storage bucket is used."
}

variable "cos_target_name" {
  type        = string
  description = "Name of the cos target for activity tracker event routing."
  default     = null
}

variable "cloud_logs_target_name" {
  type        = string
  description = "Name of the cloud logs target for activity tracker event routing."
  default     = null
}

variable "activity_tracker_cos_route_name" {
  type        = string
  description = "Name of the cos route for activity tracker event routing."
  default     = null
}

variable "activity_tracker_cloud_logs_route_name" {
  type        = string
  description = "Name of the cloud logs route for activity tracker event routing."
  default     = null
}

variable "activity_tracker_cos_target_bucket_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned Cloud Object Storage bucket. Specify one of the following values for the storage class: `standard`, `vault`, `cold`, `smart` (default), or `onerate_active`."
  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.activity_tracker_cos_target_bucket_class)
    error_message = "Specify one of the following values for the `cos_bucket_class`:  `standard`, `vault`, `cold`, `smart`, or `onerate_active`."
  }
}

variable "activity_tracker_cos_bucket_access_tags" {
  type        = list(string)
  default     = []
  description = "A list of optional access tags to add to the IBM Cloud Activity Tracker Event Routing Cloud Object Storage bucket."
}

variable "activity_tracker_cos_bucket_retention_policy" {
  type = object({
    default   = optional(number, 90)
    maximum   = optional(number, 350)
    minimum   = optional(number, 90)
    permanent = optional(bool, false)
  })
  description = "The retention policy of the IBM Cloud Activity Tracker Event Routing COS target bucket."
  default     = null
}

variable "enable_activity_tracker_event_routing_to_cloud_logs" {
  type        = bool
  description = "When set to `true`, you must provide a value for `existing_cloud_logs_crn` to enable event routing from Activity Tracker to a Cloud Logs instance."
  default     = true
}

variable "skip_activity_tracker_cos_auth_policy" {
  type        = bool
  description = "To skip creating an IAM authorization policy that allows the Activity Tracker to write to the Cloud Object Storage instance, set this variable to `true`."
  default     = false
}

########################################################################################################################
# App Config variables
########################################################################################################################

variable "app_config_name" {
  type        = string
  description = "Name for the App Configuration service instance."
  default     = "app-config"
  nullable    = false
}

variable "app_config_plan" {
  type        = string
  description = "Plan for the App Configuration service instance."
  default     = "enterprise"
  nullable    = false
}

variable "app_config_service_endpoints" {
  type        = string
  description = "Service Endpoints for the App Configuration service instance, valid endpoints are public or public-and-private."
  default     = "public-and-private"
  nullable    = false

  validation {
    condition     = contains(["public", "public-and-private"], var.app_config_service_endpoints)
    error_message = "Value for service endpoints must be one of the following: \"public\" or \"public-and-private\"."
  }
}

variable "app_config_collections" {
  description = "(Optional, list) A list of collections to be added to the App Configuration instance. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-app-configuration/tree/main/solutions/fully-configurable/DA-collections.md)."
  type = list(object({
    name          = string
    collection_id = string
    description   = optional(string, null)
    tags          = optional(string, null)
  }))
  default = []

  validation {
    condition = (
      var.app_config_plan != "lite" ||
      length(var.app_config_collections) <= 1
    )
    error_message = "When using the 'lite' plan, you can define at most 1 App Configuration collection."
  }
}

variable "app_config_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the App Config instance."
  default     = []
}

variable "enable_config_aggregator" {
  description = "Set to true to enable configuration aggregator. By setting to true a trusted profile will be created with the required access to record configuration data from all resources across regions in your account. [Learn more](https://cloud.ibm.com/docs/app-configuration?topic=app-configuration-ac-configuration-aggregator)."
  type        = bool
  default     = true
  nullable    = false

  # Lite plan does not support enabling Config Aggregator as mention in doc : https://cloud.ibm.com/docs/app-configuration?topic=app-configuration-ac-configuration-aggregator
  validation {
    condition     = !(var.enable_config_aggregator && var.app_config_plan == "lite")
    error_message = "The configuration aggregator cannot be enabled when the app_config_plan is set to 'lite'. Please use a different plan (e.g., 'basic', 'standardv2', or 'enterprise')."
  }
}

variable "config_aggregator_trusted_profile_name" {
  description = "The name to give the trusted profile that will be created if `enable_config_aggregator` is set to `true`. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  type        = string
  default     = "config-aggregator-trusted-profile"

  validation {
    condition     = var.enable_config_aggregator ? var.config_aggregator_trusted_profile_name != null : true
    error_message = "'config_aggregator_trusted_profile_name' cannot be null if 'enable_config_aggregator' is true."
  }
}

variable "config_aggregator_resource_collection_regions" {
  type        = list(string)
  description = "From which region do you want to collect configuration data? Only applies if `enable_config_aggregator` is set to true."
  default     = ["all"]
}

variable "config_aggregator_enterprise_id" {
  type        = string
  description = "If the account is an enterprise account, this value should be set to the enterprise ID (NOTE: This is different to the account ID). "
  default     = null

  validation {
    condition     = !var.enable_config_aggregator ? var.config_aggregator_enterprise_id == null : true
    error_message = "A value can only be passed for 'config_aggregator_enterprise_id' if 'enable_config_aggregator' is true."
  }
}

variable "config_aggregator_enterprise_trusted_profile_name" {
  description = "The name to give the enterprise viewer trusted profile with that will be created if `enable_config_aggregator` is set to `true` and a value is passed for `config_aggregator_enterprise_id`. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  type        = string
  default     = "config-aggregator-enterprise-trusted-profile"

  validation {
    condition     = var.enable_config_aggregator && var.config_aggregator_enterprise_id != null ? var.config_aggregator_enterprise_trusted_profile_name != null : true
    error_message = "'config_aggregator_enterprise_trusted_profile_name' cannot be null if 'enable_config_aggregator' is true and a value is being passed for 'config_aggregator_enterprise_id'."
  }
}

variable "config_aggregator_enterprise_trusted_profile_template_name" {
  description = "The name to give the trusted profile template that will be created if `enable_config_aggregator` is set to `true` and a value is passed for `config_aggregator_enterprise_id`. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  type        = string
  default     = "config-aggregator-trusted-profile-template"

  validation {
    condition     = var.enable_config_aggregator && var.config_aggregator_enterprise_id != null ? var.config_aggregator_enterprise_trusted_profile_template_name != null : true
    error_message = "'config_aggregator_enterprise_trusted_profile_template_name' cannot be null if 'enable_config_aggregator' is true and a value is being passed for 'config_aggregator_enterprise_id'."
  }
}

variable "config_aggregator_enterprise_account_group_ids_to_assign" {
  type        = list(string)
  default     = ["all"]
  description = "A list of enterprise account group IDs to assign the trusted profile template to in order for the accounts to be scanned. Supports passing the string 'all' in the list to assign to all account groups. Only applies if `enable_config_aggregator` is true and a value is being passed for `config_aggregator_enterprise_id`."
  nullable    = false

  validation {
    condition     = contains(var.config_aggregator_enterprise_account_group_ids_to_assign, "all") ? length(var.config_aggregator_enterprise_account_group_ids_to_assign) == 1 : true
    error_message = "When specifying 'all' in the list, you cannot add any other values to the list"
  }
}

variable "config_aggregator_enterprise_account_ids_to_assign" {
  type        = list(string)
  default     = []
  description = "A list of enterprise account IDs to assign the trusted profile template to in order for the accounts to be scanned. Supports passing the string 'all' in the list to assign to all accounts. Only applies if `enable_config_aggregator` is true and a value is being passed for `config_aggregator_enterprise_id`."
  nullable    = false

  validation {
    condition     = contains(var.config_aggregator_enterprise_account_ids_to_assign, "all") ? length(var.config_aggregator_enterprise_account_ids_to_assign) == 1 : true
    error_message = "When specifying 'all' in the list, you cannot add any other values to the list"
  }
}

variable "skip_app_config_kms_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits App configuration instances in the resource group to read the encryption key from the KMS instance in the same account. If a value is specified for `ibmcloud_kms_api_key`, the policy is created in the other account."
  default     = false
}

variable "skip_app_config_event_notifications_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits App configuration instances to integrate with Event Notification in the same account."
  default     = false
}

variable "app_config_event_notifications_source_name" {
  type        = string
  description = "The name by which Event Notifications source will be created in the existing Event Notification instance."
  default     = "app-config-en"
}

variable "apprapp_cbr_rules" {
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
  description = "The list of context-based restrictions rules to create. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-cbr_rules.md)."
  default     = []
}

#######################################################################################################################
# SCC Workload Protection
#######################################################################################################################

variable "scc_workload_protection_instance_name" {
  description = "The name for the Workload Protection instance that is created by this solution. Must begin with a letter. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<instance_name>` format."
  type        = string
  default     = "scc-workload-protection"
}

variable "scc_workload_protection_trusted_profile_name" {
  description = "The name to give the trusted profile that is created by this module if `cspm_enabled` is `true. Must begin with a letter. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<profile_name>` format."
  type        = string
  default     = "workload-protection-trusted-profile"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9\\-_\\.]+$", var.scc_workload_protection_trusted_profile_name))
    error_message = "The trusted profile name must begin with a letter and can only contain letters, numbers, hyphens, underscores, and periods."
  }
  validation {
    condition     = !(var.cspm_enabled && var.scc_workload_protection_trusted_profile_name == null)
    error_message = "Cannot be `null` if `cspm_enabled` is `true`."
  }
}

variable "scc_workload_protection_instance_tags" {
  type        = list(string)
  description = "The list of tags to add to the Workload Protection instance."
  default     = []
}

variable "scc_workload_protection_resource_key_tags" {
  type        = list(string)
  description = "The tags associated with the Workload Protection resource key."
  default     = []
}

variable "scc_workload_protection_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Workload Protection instance. Maximum length: 128 characters. Possible characters are A-Z, 0-9, spaces, underscores, hyphens, periods, and colons."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.scc_workload_protection_access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits for more details"
  }
}

variable "scc_workload_protection_service_plan" {
  description = "The pricing plan for the Workload Protection instance service. Possible values: `free-trial`, `graduated-tier`."
  type        = string
  default     = "graduated-tier"
  validation {
    error_message = "Plan for Workload Protection instances can only be `free-trial` or `graduated-tier`."
    condition = contains(
      ["free-trial", "graduated-tier"],
      var.scc_workload_protection_service_plan
    )
  }
}

variable "cspm_enabled" {
  description = "Enable Cloud Security Posture Management (CSPM) for the Workload Protection instance. This will create a trusted profile associated with the SCC Workload Protection instance that has viewer / reader access to the App Config service and viewer access to the Enterprise service."
  type        = bool
  default     = true
  nullable    = false
}

variable "scc_wp_cbr_rules" {
  type = list(object({
    description = string
    account_id  = string
    rule_contexts = list(object({
      attributes = optional(list(object({
        name  = string
        value = string
    }))) }))
    enforcement_mode = string
    tags = optional(list(object({
      name  = string
      value = string
    })), [])
    operations = optional(list(object({
      api_types = list(object({
        api_type_id = string
      }))
    })))
  }))
  description = "The list of context-based restriction rules to create for the instance."
  default     = []
  # Validation happens in the rule module
}

#######################################################################################################################
# VPC and VPE
#######################################################################################################################

variable "enable_vpc_flow_logs" {
  description = "To enable VPC Flow logs, set this to true."
  type        = bool
  nullable    = false
  default     = false
}

variable "vpc_name" {
  default     = "vpc"
  description = "Name of the VPC. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  type        = string
}

variable "flow_logs_cos_bucket_name" {
  description = "Name of the Cloud Object Storage bucket to be created to collect VPC flow logs."
  type        = string
  default     = "flow-logs-bucket"
}

variable "vpc_resource_tags" {
  type        = list(string)
  description = "The list of tags to add to the VPC instance."
  default     = []
}

variable "vpc_access_tags" {
  type        = list(string)
  description = "The list of access tags to add to the VPC instance."
  default     = []
}

variable "vpc_flow_logs_access_tags" {
  type        = list(string)
  description = "The list of access tags to add to the VPC instance."
  default     = []
}

variable "flow_logs_cos_bucket_archive_days" {
  description = "The number of days before the `archive_type` rule action takes effect for the flow logs cloud object storage bucket."
  type        = number
  default     = 90
}

variable "flow_logs_cos_bucket_archive_type" {
  description = "The storage class or archive type you want the object to transition to in the flow logs cloud object storage bucket."
  type        = string
  default     = "Glacier"
  validation {
    condition     = contains(["Glacier", "Accelerated"], var.flow_logs_cos_bucket_archive_type)
    error_message = "The specified flow_logs_cos_bucket_archive_type is not a valid selection!"
  }
}

variable "flow_logs_cos_bucket_expire_days" {
  description = "The number of days before the expire rule action takes effect for the flow logs cloud object storage bucket."
  type        = number
  default     = 366
}

variable "flow_logs_cos_bucket_enable_object_versioning" {
  description = "Set it to true if object versioning is enabled so that multiple versions of an object are retained in the flow logs cloud object storage bucket. Cannot be used if `flow_logs_cos_bucket_enable_retention` is true."
  type        = bool
  nullable    = false
  default     = false

  validation {
    condition     = var.flow_logs_cos_bucket_enable_object_versioning ? (var.flow_logs_cos_bucket_enable_retention ? false : true) : true
    error_message = "`flow_logs_cos_bucket_enable_object_versioning` cannot set true if `flow_logs_cos_bucket_enable_retention` is true."
  }
}

variable "flow_logs_cos_bucket_enable_retention" {
  description = "Set to true to enable retention for the flow logs cloud object storage bucket."
  type        = bool
  nullable    = false
  default     = false
}

variable "flow_logs_cos_bucket_default_retention_days" {
  description = "The number of days that an object can remain unmodified in the flow logs cloud object storage bucket."
  type        = number
  default     = 90
}

variable "flow_logs_cos_bucket_maximum_retention_days" {
  description = "The maximum number of days that an object can be kept unmodified in the flow logs cloud object storage."
  type        = number
  default     = 350
}

variable "flow_logs_cos_bucket_minimum_retention_days" {
  description = "The minimum number of days that an object must be kept unmodified in the flow logs cloud object storage."
  type        = number
  default     = 90
}

variable "flow_logs_cos_bucket_enable_permanent_retention" {
  description = "Whether permanent retention status is enabled for the flow logs cloud object storage bucket."
  type        = bool
  nullable    = false
  default     = false
}

variable "subnets" {
  description = "List of subnets for the vpc. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total ipv4 addresses. Public gateways will be enabled only in zones where a gateway has been createds."
  type = object({
    zone-1 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
      no_addr_prefix = optional(bool, false) # do not automatically add address prefix for subnet, overrides other conditions if set to true
      subnet_tags    = optional(list(string), [])
    }))
    zone-2 = optional(list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
      no_addr_prefix = optional(bool, false) # do not automatically add address prefix for subnet, overrides other conditions if set to true
      subnet_tags    = optional(list(string), [])
    })))
    zone-3 = optional(list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
      no_addr_prefix = optional(bool, false) # do not automatically add address prefix for subnet, overrides other conditions if set to true
      subnet_tags    = optional(list(string), [])
    })))
  })

  default = {
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

  validation {
    condition     = alltrue([for key, value in var.subnets : value != null ? length([for subnet in value : subnet.public_gateway if subnet.public_gateway]) > 1 ? false : true : true])
    error_message = "var.subnets has more than one public gateway in a zone. Only one public gateway can be attached to a zone for the virtual private cloud."
  }
}

variable "default_network_acl_name" {
  description = "Name of the Default ACL. If null, a name will be automatically generated."
  type        = string
  default     = null
}

variable "default_security_group_name" {
  description = "Name of the Default Security Group. If null, a name will be automatically generated."
  type        = string
  default     = null
}

variable "default_routing_table_name" {
  description = "Name of the Default Routing Table. If null, a name will be automatically generated."
  type        = string
  default     = null
}

variable "network_acls" {
  description = "The list of ACLs to create. Provide at least one rule for each ACL."
  type = list(
    object({
      name                         = string
      add_ibm_cloud_internal_rules = optional(bool)
      add_vpc_connectivity_rules   = optional(bool)
      prepend_ibm_rules            = optional(bool)
      rules = list(
        object({
          name        = string
          action      = string
          destination = string
          direction   = string
          source      = string
          tcp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          udp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          icmp = optional(
            object({
              type = optional(number)
              code = optional(number)
            })
          )
        })
      )
    })
  )

  default = [
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

  validation {
    error_message = "ACL rule actions can only be `allow` or `deny`."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([var.network_acls[*].rules]) :
        # Return false action is not valid
        false if !contains(["allow", "deny"], rule.action)
      ])
    )) == 0
  }

  validation {
    error_message = "ACL rule direction can only be `inbound` or `outbound`."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([var.network_acls[*].rules]) :
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "ACL rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([var.network_acls[*].rules]) :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }

}

##############################################################################
# Default Security Group Rules
##############################################################################

variable "security_group_rules" {
  description = "A list of security group rules to be added to the default vpc security group (default empty)."
  default     = []
  type = list(
    object({
      name       = string
      direction  = string
      remote     = optional(string)
      local      = optional(string)
      ip_version = optional(string)
      tcp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = (var.security_group_rules == null || length(var.security_group_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.security_group_rules :
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = (var.security_group_rules == null || length(var.security_group_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.security_group_rules :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }
}

variable "clean_default_security_group_acl" {
  description = "Remove all rules from the default VPC security group and VPC ACL (less permissive)."
  type        = bool
  nullable    = false
  default     = true
}

##############################################################################
# Address Prefixes
##############################################################################

variable "address_prefixes" {
  description = "The IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes."
  type = object({
    zone-1 = optional(list(string))
    zone-2 = optional(list(string))
    zone-3 = optional(list(string))
  })
  default = {
    zone-1 = null
    zone-2 = null
    zone-3 = null
  }
  validation {
    error_message = "Keys for `use_public_gateways` must be in the order `zone-1`, `zone-2`, `zone-3`."
    condition = var.address_prefixes == null ? true : (
      (length(var.address_prefixes) == 1 && keys(var.address_prefixes)[0] == "zone-1") ||
      (length(var.address_prefixes) == 2 && keys(var.address_prefixes)[0] == "zone-1" && keys(var.address_prefixes)[1] == "zone-2") ||
      (length(var.address_prefixes) == 3 && keys(var.address_prefixes)[0] == "zone-1" && keys(var.address_prefixes)[1] == "zone-2") && keys(var.address_prefixes)[2] == "zone-3"
    )
  }
}

##############################################################################
# Add routes to VPC
##############################################################################

variable "routes" {
  description = "Allows you to specify the next hop for packets based on their destination address."
  type = list(
    object({
      name                          = string
      route_direct_link_ingress     = optional(bool)
      route_transit_gateway_ingress = optional(bool)
      route_vpc_zone_ingress        = optional(bool)
      routes = optional(
        list(
          object({
            action      = optional(string)
            zone        = number
            destination = string
            next_hop    = string
          })
      ))
    })
  )
  default = []
}

variable "skip_vpc_cos_iam_auth_policy" {
  description = "To skip creating an IAM authorization policy that allows the VPC to access the Cloud Object Storage, set this variable to `true`. Required only if `enable_vpc_flow_logs` is set to true."
  type        = bool
  nullable    = false
  default     = false
}

variable "vpn_gateways" {
  description = "List of VPN Gateways to create."
  nullable    = false
  type = list(
    object({
      name           = string
      subnet_name    = string # Do not include prefix, use same name as in `var.subnets`
      mode           = optional(string)
      resource_group = optional(string)
      access_tags    = optional(list(string), [])
    })
  )

  default = []
}

variable "vpe_gateway_cloud_services" {
  description = "The list of cloud services used to create endpoint gateways. If `vpe_name` is not specified in the list, VPE names are created in the format `<prefix>-<vpc_name>-<service_name>`."
  type = set(object({
    service_name                 = string
    vpe_name                     = optional(string), # Full control on the VPE name. If not specified, the VPE name will be computed based on prefix, vpc name and service name.
    allow_dns_resolution_binding = optional(bool, false)
  }))
  default = []
}

variable "vpe_gateway_cloud_service_by_crn" {
  description = "The list of cloud service CRNs used to create endpoint gateways. Use this list to identify services that are not supported by service name in the `cloud_services` variable. For a list of supported services, see [VPE-enabled services](https://cloud.ibm.com/docs/vpc?topic=vpc-vpe-supported-services). If `service_name` is not specified, the CRN is used to find the name. If `vpe_name` is not specified in the list, VPE names are created in the format `<prefix>-<vpc_name>-<service_name>`."
  type = set(
    object({
      crn                          = string
      vpe_name                     = optional(string) # Full control on the VPE name. If not specified, the VPE name will be computed based on prefix, vpc name and service name.
      service_name                 = optional(string) # Name of the service used to compute the name of the VPE. If not specified, the service name will be obtained from the crn.
      allow_dns_resolution_binding = optional(bool, true)
    })
  )
  default = []
}

variable "vpe_gateway_service_endpoints" {
  description = "Service endpoints to use to create endpoint gateways. Can be `public`, or `private`."
  type        = string
  default     = "private"

  validation {
    error_message = "Service endpoints can only be `public` or `private`."
    condition     = contains(["public", "private"], var.vpe_gateway_service_endpoints)
  }
}

variable "vpe_gateway_security_group_ids" {

  # Currently unused — the DA doesn't create any custom security groups.
  # The default security group (automatically created with the VPC) is attached to the VPE gateway since no other security groups are present.
  # May be useful in the future when DA supports using an existing VPC with custom security groups or if DA supports creating additional security groups we can take `vpe_gateway_security_group_names` as input.

  description = "List of security group ids to attach to each endpoint gateway."
  type        = list(string)
  default     = null # Let this default value be null instead of []. Provider issue - https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4546
}

variable "vpe_gateway_reserved_ips" {
  description = "Map of existing reserved IP names and values. Leave this value as default if you want to create new reserved ips, this value is used when a user passes their existing reserved ips created here and not attempt to recreate those."
  type = object({
    name = optional(string) # reserved ip name
  })
  default = {}
}

########################################################################################################################
# OCP VPC cluster
########################################################################################################################

variable "cluster_name" {
  type        = string
  description = "The name of the new IBM Cloud OpenShift Cluster. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "openshift"
}

variable "default_worker_pool_machine_type" {
  type        = string
  description = "The machine type for worker nodes."
  default     = "bx2.4x16"
  validation {
    condition     = length(regexall("^[a-z0-9]+(?:\\.[a-z0-9]+)*\\.\\d+x\\d+(?:\\.[a-z0-9]+)?$", var.default_worker_pool_machine_type)) > 0
    error_message = "Invalid value provided for the machine type."
  }
}

variable "default_worker_pool_workers_per_zone" {
  type        = number
  description = "Number of worker nodes in each zone of the cluster."
  default     = 1
}

variable "default_worker_pool_operating_system" {
  type        = string
  description = "The operating system installed on the worker nodes."
  default     = "RHCOS"
}

variable "default_worker_pool_labels" {
  type        = map(string)
  description = "A set of key-value labels assigned to the worker pool for identification."
  default     = {}
}

variable "default_pool_minimum_number_of_nodes" {
  type        = number
  description = "The minimum number of worker nodes allowed in the pool, ensuring at least one worker is always running."
  default     = 1
}

variable "default_pool_maximum_number_of_nodes" {
  type        = number
  description = "The maximum number of worker nodes allowed in the pool, preventing the pool from exceeding three workers."
  default     = 3
}

variable "additional_security_group_ids" {
  type        = list(string)
  description = "A list of security group IDs that are attached to the worker nodes for additional network security controls."
  default     = []
}

variable "additional_worker_pools" {
  type = list(object({
    vpc_subnets = optional(list(object({
      id         = string
      zone       = string
      cidr_block = string
    })), [])
    pool_name                     = string
    machine_type                  = string
    workers_per_zone              = number
    operating_system              = string
    labels                        = optional(map(string))
    minSize                       = optional(number)
    secondary_storage             = optional(string)
    maxSize                       = optional(number)
    enableAutoscaling             = optional(bool)
    additional_security_group_ids = optional(list(string))
  }))
  description = "List of additional worker pools."
  default     = []
}

variable "enable_autoscaling_for_default_pool" {
  type        = bool
  description = "Set `true` to enable automatic scaling of worker based on workload demand."
  default     = false
}

variable "addons" {
  type = object({
    debug-tool = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    image-key-synchronizer = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    openshift-data-foundation = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    vpc-file-csi-driver = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    static-route = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    cluster-autoscaler = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    vpc-block-csi-driver = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    ibm-storage-operator = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    openshift-ai = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
  })
  description = "Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters and 'ibm-storage-operator' is installed by default in OCP 4.15 and later, however you can explicitly specify it here if you wish to choose a later version than the default one). [Check supported addons and versions here](https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions)."
  nullable    = false
  default     = {}
}

variable "openshift_version" {
  type        = string
  description = "Version of the OpenShift cluster to provision."
  default     = "4.19"
}

variable "cluster_resource_tags" {
  type        = list(string)
  description = "Metadata labels describing this cluster deployment, i.e. test."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module."
  default     = []
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning."
  default     = null
}

variable "additional_lb_security_group_ids" {
  description = "List of additional security group IDs to add to the load balancers associated with the cluster. Ensure that the `number_of_lbs` variable is set to the number of Load Balancers associated with the cluster. This comes in addition to the IBM maintained security group."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "number_of_lbs" {
  description = "The total number of Load Balancers in the cluster that should be associated with the security groups defined in `additional_lb_security_group_ids` variable."
  type        = number
  default     = 1
  nullable    = false
}

variable "additional_vpe_security_group_ids" {
  description = "Additional security groups to add to all existing load balancers. This comes in addition to the IBM maintained security group."
  type = object({
    master   = optional(list(string), [])
    registry = optional(list(string), [])
    api      = optional(list(string), [])
  })
  default = {}
}

variable "allow_default_worker_pool_replacement" {
  type        = bool
  description = "Set to true to allow the module to recreate a default worker pool. Only use in the case where you are getting an error indicating that the default worker pool cannot be replaced on apply. Once the default worker pool is handled separately, if you wish to make any change to the default worker pool which requires the re-creation of the default pool set this variable to true."
  default     = false
  nullable    = false
}

variable "attach_ibm_managed_security_group" {
  description = "Specify whether to attach the IBM-defined default security group (whose name is kube-<clusterid>) to all worker nodes. Only applicable if `custom_security_group_ids` is set."
  type        = bool
  default     = true
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for cluster config access: 'default', 'private', 'vpe', 'link'. A 'default' value uses the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false
}

variable "verify_worker_network_readiness" {
  type        = bool
  description = "By setting this to true, a script runs kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, set this value to false."
  default     = true
}

variable "cluster_ready_when" {
  type        = string
  description = "The cluster is ready based on one of the following:: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady."
  default     = "IngressReady"
}

variable "custom_security_group_ids" {
  description = "Security groups to add to all worker nodes. This comes in addition to the IBM maintained security group if `attach_ibm_managed_security_group` is set to true. If this variable is set, the default VPC security group is NOT assigned to the worker nodes."
  type        = list(string)
  default     = null
}

variable "allow_outbound_traffic" {
  type        = bool
  description = "Set to true to allow public outbound access from the cluster workers."
  default     = true
}

variable "allow_public_access_to_cluster_management" {
  type        = bool
  description = "Set to true to access the cluster through a public cloud service endpoint."
  default     = true
}

variable "enable_ocp_console" {
  description = "Flag to specify whether to enable or disable the OpenShift console. If set to `null` the module does not modify the current setting on the cluster. Keep in mind that when this input is set to `true` or `false` on a cluster with private only endpoint enabled, the runtime must be able to access the private endpoint."
  type        = bool
  default     = null
  nullable    = true
}

variable "ignore_worker_pool_size_changes" {
  type        = bool
  description = "Enable if using worker autoscaling. Stops Terraform managing worker count."
  default     = false
}

variable "manage_all_addons" {
  type        = bool
  default     = false
  nullable    = false
  description = "Instructs deployable architecture to manage all cluster addons, even if addons were installed outside of the module. If set to 'true' this deployable architecture destroys any addons that were installed by other sources."
}

variable "pod_subnet_cidr" {
  type        = string
  description = "Specify a custom subnet CIDR to provide private IP addresses for pods. The subnet must have a CIDR of at least `/23` or larger. Default value is `172.30.0.0/16` when the variable is set to `null`."
  default     = null
}

variable "service_subnet_cidr" {
  type        = string
  description = "Specify a custom subnet CIDR to provide private IP addresses for services. The subnet must be at least `/24` or larger. Default value is `172.21.0.0/16` when the variable is set to `null`."
  default     = null
}

variable "worker_pools_taints" {
  type        = map(list(object({ key = string, value = string, effect = string })))
  description = "Optional, Map of lists containing node taints by node-pool name."
  default     = null
}

variable "enable_secrets_manager_integration" {
  type        = bool
  description = "Integrate with IBM Cloud Secrets Manager so you can centrally manage Ingress subdomain certificates and other secrets."
  default     = true
  nullable    = false
}

variable "secrets_manager_secret_group_id" {
  type        = string
  description = "Secret group ID where Ingress secrets are stored in the Secrets Manager instance. If 'enable_secrets_manager_integration' is set to true and 'secrets_manager_secret_group_id' is not provided, a new group will be created with the same name as cluster_id."
  default     = null
}

variable "skip_ocp_secrets_manager_iam_auth_policy" {
  type        = bool
  description = "To skip creating auth policy that allows OCP cluster 'Manager' role access in the existing Secrets Manager instance for managing ingress certificates."
  default     = false
}

variable "ocp_cbr_rules" {
  type = list(object({
    description = string
    account_id  = string
    rule_contexts = list(object({
      attributes = optional(list(object({
        name  = string
        value = string
    }))) }))
    enforcement_mode = string
    tags = optional(list(object({
      name  = string
      value = string
    })), [])
    operations = optional(list(object({
      api_types = list(object({
        api_type_id = string
      }))
    })))
  }))
  description = "The list of context-based restriction rules to create."
  default     = []
}
