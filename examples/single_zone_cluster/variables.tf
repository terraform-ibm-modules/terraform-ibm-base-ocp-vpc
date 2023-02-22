##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API key associated with the account."
  sensitive   = true
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "base-ocp-sz"
  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  type        = string
  description = "Region where resources are created."
  default     = "us-east"
}

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision."
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

variable "cluster_zone_list" {
  type        = list(string)
  description = "A list of the availability zones (AZ) to provision the cluster in. Example: `cluster_zone_list = [\"1\"]` will provision a cluster in only one zone, e.g., us-south-1"
  default     = ["1"] # Single Zone

  # Validation rules
  validation {
    condition     = alltrue([for zone in var.cluster_zone_list : contains(["1", "2", "3"], zone)])
    error_message = "A cluster_zone_list value must be a string of \"1\", \"2\" or \"3\"."
  }
  validation {
    condition     = length(var.cluster_zone_list) == length(distinct(var.cluster_zone_list))
    error_message = "A cluster_zone_list value must be a unique string of \"1\", \"2\" or \"3\" within the list."
  }
  validation {
    condition     = length(var.cluster_zone_list) >= 1 && length(var.cluster_zone_list) <= 3
    error_message = "The cluster_zone_list only allows for specifying a minimum of one zone up to a maximum of three zones."
  }
}
##############################################################################
