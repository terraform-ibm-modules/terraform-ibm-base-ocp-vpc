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
    labels            = optional(map(string))
    minSize           = optional(number)
    maxSize           = optional(number)
    enableAutoscaling = optional(bool)
    boot_volume_encryption_kms_config = optional(object({
      crk             = string
      kms_instance_id = string
      kms_account_id  = optional(string)
    }))
  }))
  description = "List of worker pools"
  validation {
    error_message = "Please provide value for minSize and maxSize while enableAutoscaling is set to true."
    condition = length(
      flatten(
        [
          for worker in var.worker_pools :
          worker if worker.enableAutoscaling == true && worker.minSize != null && worker.maxSize != null
        ]
      )
      ) == length(
      flatten(
        [
          for worker in var.worker_pools :
          worker if worker.enableAutoscaling == true
        ]
      )
    )
  }
  validation {
    condition     = length([for worker_pool in var.worker_pools : worker_pool if(worker_pool.subnet_prefix == null && worker_pool.vpc_subnets == null) || (worker_pool.subnet_prefix != null && worker_pool.vpc_subnets != null)]) == 0
    error_message = "Please provide exactly one of subnet_prefix or vpc_subnets. Passing neither or both is invalid."
  }
}

variable "worker_pools_taints" {
  type        = map(list(object({ key = string, value = string, effect = string })))
  description = "Optional, Map of lists containing node taints by node-pool name"
  default     = null
}

variable "ignore_worker_pool_size_changes" {
  type        = bool
  description = "Enable if using worker autoscaling. Stops Terraform managing worker count"
  default     = false
}

variable "ocp_version" {
  type        = string
  description = "The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. Supports passing the string 'latest' (current latest available version) or 'default' (current IKS default recommended version). If no value is passed, it will default to 'default'."
  default     = null

  validation {
    condition = anytrue([
      var.ocp_version == null,
      var.ocp_version == "default",
      var.ocp_version == "latest",
      var.ocp_version == "4.10",
      var.ocp_version == "4.11",
      var.ocp_version == "4.12",
      var.ocp_version == "4.13",
    ])
    error_message = "The specified ocp_version is not of the valid versions."
  }
}

variable "cluster_ready_when" {
  type        = string
  description = "The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady"
  default     = "IngressReady"

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

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details"
  default     = []

  validation {
    condition = alltrue([
      for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits for more details"
  }
}

# VPC Variables
variable "vpc_id" {
  type        = string
  description = "Id of the VPC instance where this cluster will be provisioned"
}

variable "verify_worker_network_readiness" {
  type        = bool
  description = "By setting this to true, a script will run kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, this should be set to false."
  default     = true
}

variable "addons" {
  type = object({
    alb-oauth-proxy           = optional(string)
    debug-tool                = optional(string)
    image-key-synchronizer    = optional(string)
    istio                     = optional(string)
    openshift-data-foundation = optional(string)
    static-route              = optional(string)
    cluster-autoscaler        = optional(string)
    vpc-block-csi-driver      = optional(string)
  })
  description = "List of all addons supported by the ocp cluster."
  default     = null
}

##############################################################################
