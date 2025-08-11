##############################################################################
# Input Variables
##############################################################################

# Resource Group Variables
variable "group_id" {
  type        = string
  description = "The ID of an existing IBM Cloud resource group where the cluster is grouped."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster is provisioned."
}

variable "use_private_endpoint" {
  type        = bool
  description = "Set this to true to force all API calls to use the IBM Cloud private endpoints."
  default     = false
}

# Cluster Variables
variable "tags" {
  type        = list(string)
  description = "Metadata labels describing this cluster deployment, i.e. test"
  default     = []
}

variable "cluster_name" {
  type        = string
  description = "The name that is assigned to the provisioned cluster."
}

variable "subnets" {
  type = map(list(object({
    id         = string
    zone       = string
    cidr_block = string
  })))
  description = "Metadata that describes the VPC's subnets. Obtain this information from the VPC where this cluster is created."
}

variable "allow_default_worker_pool_replacement" {
  type        = bool
  description = "(Advanced users) Set to true to allow the module to recreate a default worker pool. If you wish to make any change to the default worker pool which requires the re-creation of the default pool follow these [steps](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#important-considerations-for-terraform-and-default-worker-pool)."
  default     = false
  nullable    = false
}
