########################################################################################################################
# Input variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "ocp-lz"
  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  type        = string
  description = "Region where resources are created"
  default     = "us-south"
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

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources."
  default     = "Default"
}

variable "existing_event_notifications_instance_crn" {
  type        = string
  description = "The CRN of the Event Notifications service used to enable lifecycle notifications for your Secrets Manager instance."
  default     = null
}

variable "existing_kms_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing KMS instance."

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

variable "existing_secrets_manager_crn" {
  type        = string
  description = "The CRN of an existing Secrets Manager instance. If not supplied, a new instance is created."
  default     = null
}


variable "existing_cos_instance_crn" {
  type        = string
  description = "The CRN of an existing Object Storage instance."
  default     = null
}

variable "existing_cloud_monitoring_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing Cloud Monitoring instance. If not supplied, a new instance will be created."
}

variable "existing_cloud_logs_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing Cloud Logs instance. If not supplied, a new instance will be created."
}
