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

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "base-ocp-existing-cos"
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

variable "vpc_subnets" {
  type = map(list(object({
    id         = string
    zone       = string
    cidr_block = string
  })))
  description = "Metadata that describes the VPC's subnets. Obtain this information from the VPC where this cluster will be created"
}

variable "vpc_id" {
  type        = string
  description = "Id of the VPC instance where this cluster will be provisioned"
}

variable "existing_cos_id" {
  type        = string
  description = "The ID of an existing COS instance to use for cluster provisioning"
}


##############################################################################