##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to use, set via environment variable TF_VAR_ibmcloud_api_key"
  type        = string
  sensitive   = true
}

# Resource Group Variables
variable "resource_group_id" {
  type        = string
  description = "The Id of an existing IBM Cloud resource group where the cluster will be grouped."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster will be provisioned."
}

# Cluster Variables
variable "tags" {
  type        = list(string)
  description = "Metadata labels describing this cluster deployment, i.e. test"
  default     = []
}

variable "cluster_name" {
  type        = string
  description = "The name that will be assigned to the provisioned cluster"
}

variable "vpc_subnets" {
  type = map(list(object({
    id         = string
    zone       = string
    cidr_block = string
  })))
  description = "Metadata that describes the VPC's subnets. Obtain this information from the VPC where this cluster will be created"
}

variable "worker_pools" {
  type = list(object({
    subnet_prefix     = string
    pool_name         = string
    machine_type      = string
    workers_per_zone  = number
    resource_group_id = optional(string)
    labels            = optional(map(string))
  }))
  default = [
    {
      subnet_prefix    = "zone-1"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      labels           = {}
    },
    {
      subnet_prefix    = "zone-2"
      pool_name        = "zone-2"
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      labels           = { "dedicated" : "zone-2" }
    },
    {
      subnet_prefix    = "zone-3"
      pool_name        = "zone-3"
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      labels           = { "dedicated" : "zone-3" }
    }
  ]
  description = "List of worker pools"
}

variable "worker_pools_taints" {
  type        = map(list(object({ key = string, value = string, effect = string })))
  description = "Map of lists containing node taints by node-pool name"

  default = {
    all = []
    zone-3 = [{
      key    = "dedicated"
      value  = "zone-3"
      effect = "NoExecute"
    }]
    zone-2 = [{
      key    = "dedicated"
      value  = "zone-2"
      effect = "NoExecute"
    }]
    default = []
  }
}

variable "ignore_worker_pool_size_changes" {
  type        = bool
  description = "Enable if using worker autoscaling. Stops Terraform managing worker count"
  default     = false
}

variable "ocp_version" {
  type        = string
  description = "The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. If no value is passed, or the string 'default' is passed, the current default OCP version will be used."
  default     = null
}

variable "cluster_ready_when" {
  type        = string
  description = "The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady"
  default     = "IngressReady"
  # Set to "Normal" once provider fixes https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4214
  #   default     = "Normal"

  validation {
    condition     = contains(["MasterNodeReady", "OneWorkerNodeReady", "Normal", "IngressReady"], var.cluster_ready_when)
    error_message = "The input variable cluster_ready_when must one of: \"MasterNodeReady\", \"OneWorkerNodeReady\", \"Normal\" or \"IngressReady\"."
  }
}
variable "disable_public_endpoint" {
  type        = bool
  description = "Flag indicating that the public endpoint should be enabled or disabled"
  default     = false
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = "cloud_pak"
}

variable "force_delete_storage" {
  type        = bool
  description = "Flag indicating whether or not to delete attached storage when destroying the cluster - Default: false"
  default     = false
}

variable "cos_name" {
  type        = string
  description = "Name of the COS instance to provision. New instance only provisioned if `use_existing_cos = false`. Default: `<cluster_name>_cos`"
  default     = null
}

variable "use_existing_cos" {
  type        = bool
  description = "Flag indicating whether or not to use an existing COS instance"
  default     = false
}

variable "existing_cos_id" {
  type        = string
  description = "The COS id of an already existing COS instance. Only required if 'use_existing_cos = true'"
  default     = null
}

variable "kms_config" {
  type = object({
    crk_id           = string
    instance_id      = string
    private_endpoint = optional(bool, true) # defaults to true
  })
  description = "Use to attach a Key Protect instance to the cluster"
  default     = null
}

# VPC Variables
variable "vpc_id" {
  type        = string
  description = "Id of the VPC instance where this cluster will be provisioned"
}


##############################################################################
