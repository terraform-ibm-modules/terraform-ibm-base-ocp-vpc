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
  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  type        = string
  description = "Region where resources are created"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

# variable "resource_tags" {
#   type        = list(string)
#   description = "Optional list of tags to be added to created resources"
#   default     = []
# }

# variable "ocp_version" {
#   type        = string
#   description = "Version of the OCP cluster to provision"
#   default     = null
# }

# variable "access_tags" {
#   type        = list(string)
#   description = "A list of access tags to apply to the resources created by the module."
#   default     = []
# }

# variable "ocp_entitlement" {
#   type        = string
#   description = "Value that is applied to the entitlements for OCP cluster provisioning"
#   default     = null
# }

variable "worker_pools" {
  type = list(object({
    subnet_prefix = optional(string)
    vpc_subnets = optional(list(object({
      id         = string
      zone       = string
      cidr_block = string
    })))
    pool_name         = string
    machine_type      = string
    workers_per_zone  = number
    resource_group_id = optional(string)
    operating_system  = string
    labels            = optional(map(string))
    minSize           = optional(number)
    secondary_storage = optional(string)
    maxSize           = optional(number)
    enableAutoscaling = optional(bool)
    boot_volume_encryption_kms_config = optional(object({
      crk             = string
      kms_instance_id = string
      kms_account_id  = optional(string)
    }))
    additional_security_group_ids = optional(list(string))
  }))
  description = "List of worker pools"
  default = [{
    subnet_prefix    = "default"
    pool_name        = "myworkerpool"
    machine_type     = "bx2.4x16"
    operating_system = "RHEL_9_64"
    workers_per_zone = 2 # minimum of 2 is allowed when using single zone
  }]
}

variable "vpc_subnets" {
  type = map(list(object({
    id         = string
    zone       = string
    cidr_block = string
  })))
  description = "Metadata that describes the VPC's subnets. Obtain this information from the VPC where this cluster is created."
}

variable "cluster_id" {
  type        = string
  description = "ID of the existing openshift cluster."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC instance where this cluster is provisioned."
}

