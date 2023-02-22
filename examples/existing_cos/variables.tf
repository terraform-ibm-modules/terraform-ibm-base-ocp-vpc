##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "resource_group" {
  type        = string
  description = "Resource group to provision the cluster in"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}


variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  default     = "management"
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "base-ocp-prev-cos"
  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  type        = string
  description = "Region where resources are created"
  default     = "eu-gb"
}

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision"
  default     = null
}

variable "existing_cos_id" {
  type        = string
  description = "The ID of an existing COS instance to use for cluster provisioning"
}

##############################################################################
