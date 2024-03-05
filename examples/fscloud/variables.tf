########################################################################################################################
# Input Variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api key"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "base-ocp-std"
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

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}


variable "hpcs_instance_guid" {
  type        = string
  description = "The GUID of the Hyper Protect Crypto service to provision the encryption keys"

}

variable "hpcs_key_crn_cluster" {
  description = "CRN of the Hyper Protect Crypto service key to use to encrypt the cluster boot volume"
  type        = string
}

variable "hpcs_key_crn_worker_pool" {
  description = "CRN of the Hyper Protect Crypto service key to use to encrypt the worker pool boot volumes"
  type        = string
}

variable "existing_at_instance_crn" {
  type        = string
  description = "Optionally pass an existing activity tracker instance CRN to use in the example. If not passed, a new instance will be provisioned"
  default     = null
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  default     = "management"
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module"
  default     = []
}

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision"
  default     = null
}
