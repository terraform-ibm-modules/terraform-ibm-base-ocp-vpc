##############################################################################
# Input Variables
##############################################################################

# Resource Group Variables
variable "resource_group_id" {
  type        = string
  description = "The Id of an existing IBM Cloud resource group where the cluster will be grouped."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster will be provisioned."
}

variable "use_private_endpoint" {
  type        = bool
  description = "Set this to true to force all api calls to use the IBM Cloud private endpoints."
  default     = false
}

# Cluster Variables
variable "tags" {
  type        = list(string)
  description = "Metadata labels describing this cluster deployment"
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

variable "import_default_worker_pool_on_create" {
  type        = bool
  description = "(Advanced users) Whether to handle the default worker pool as a stand-alone ibm_container_vpc_worker_pool resource on cluster creation. Only set to false if you understand the implications of managing the default worker pool as part of the cluster resource. Set to true to import the default worker pool as a separate resource. Set to false to manage the default worker pool as part of the cluster resource."
  default     = true
  nullable    = false
}

variable "allow_default_worker_pool_replacement" {
  type        = bool
  description = "(Advanced users) Set to true to allow the module to recreate a default worker pool. Only use in the case where you are getting an error indicating that the default worker pool cannot be replaced on apply. Once the default worker pool is handled as a stand-alone ibm_container_vpc_worker_pool, if you wish to make any change to the default worker pool which requires the re-creation of the default pool set this variable to true."
  default     = false
  nullable    = false
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
}

variable "pod_subnet_cidr" {
  type        = string
  default     = null
  description = "Specify a custom subnet CIDR to provide private IP addresses for pods. The subnet must have a CIDR of at least `/23` or larger. Default value is `172.30.0.0/16` when the variable is set to `null`."
}

variable "service_subnet_cidr" {
  type        = string
  default     = null
  description = "Specify a custom subnet CIDR to provide private IP addresses for services. The subnet must be at least `/24` or larger. Default value is `172.21.0.0/16` when the variable is set to `null`."
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
  description = "The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. Supports passing the string 'default' (current IKS default recommended version). If no value is passed, it will default to 'default'."
  default     = null
}

variable "cluster_ready_when" {
  type        = string
  description = "The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady"
  default     = "IngressReady"
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = null
}

variable "force_delete_storage" {
  type        = bool
  description = "Flag indicating whether or not to delete attached storage when destroying the cluster - Default: false"
  default     = false
}
variable "existing_cos_id" {
  type        = string
  description = "The COS id of an already existing COS instance"
}

variable "kms_config" {
  type = object({
    crk_id           = string
    instance_id      = string
    private_endpoint = optional(bool, true) # defaults to true
    account_id       = optional(string)     # To attach HPCS instance from another account
    wait_for_apply   = optional(bool, true) # defaults to true so terraform will wait until the KMS is applied to the master, ready and deployed
  })
  description = "Use to attach a HPCS instance to the cluster. If account_id is not provided, defaults to the account in use."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC instance where this cluster will be provisioned"
}

variable "verify_worker_network_readiness" {
  type        = bool
  description = "By setting this to true, a script will run kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, this should be set to false."
  default     = true
}

variable "addons" {
  type = object({
    debug-tool                = optional(string)
    image-key-synchronizer    = optional(string)
    openshift-data-foundation = optional(string)
    vpc-file-csi-driver       = optional(string)
    static-route              = optional(string)
    cluster-autoscaler        = optional(string)
    vpc-block-csi-driver      = optional(string)
    ibm-storage-operator      = optional(string)
  })
  description = "Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters and 'ibm-storage-operator' is installed by default in OCP 4.15 and later, however you can explicitly specify it here if you wish to choose a later version than the default one). For full list of all supported add-ons and versions, see https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions"
  default     = {}
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details"
  default     = []
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'private', 'vpe', 'link'."
  type        = string
  default     = "private"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

variable "attach_ibm_managed_security_group" {
  description = "Specify whether to attach the IBM-defined default security group (whose name is kube-<clusterid>) to all worker nodes. Only applicable if custom_security_group_ids is set."
  type        = bool
  default     = true
}

variable "custom_security_group_ids" {
  description = "Security groups to add to all worker nodes. This comes in addition to the IBM maintained security group if use_ibm_managed_security_group is set to true. If this variable is set, the default VPC security group is NOT assigned to the worker nodes."
  type        = list(string)
  default     = null
  validation {
    condition     = var.custom_security_group_ids == null ? true : length(var.custom_security_group_ids) <= 4
    error_message = "Please provide at most 4 additional security groups."
  }
}

variable "additional_lb_security_group_ids" {
  description = "Additional security groups to add to the load balancers associated with the cluster. Ensure that the number_of_lbs is set to the number of LBs associated with the cluster. This comes in addition to the IBM maintained security group."
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = var.additional_lb_security_group_ids == null ? true : length(var.additional_lb_security_group_ids) <= 4
    error_message = "Please provide at most 4 additional security groups."
  }
}

variable "number_of_lbs" {
  description = "The number of LBs to associated the additional_lb_security_group_names security group with."
  type        = number
  default     = 1
  nullable    = false
  validation {
    condition     = var.number_of_lbs >= 1
    error_message = "Please set the number_of_lbs to a minumum of."
  }
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

variable "operating_system" {
  type        = string
  description = "The operating system of the workers in the default worker pool. If no value is specified, the current default version OS will be used. See https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_versions#openshift_versions_available ."
  default     = null
  validation {
    error_message = "RHEL 8 (REDHAT_8_64) or Red Hat Enterprise Linux CoreOS (RHCOS) are the allowed OS values. RHCOS requires VPC clusters created from 4.15 onwards. Upgraded clusters from 4.14 cannot use RHCOS."
    condition     = var.operating_system == null || var.operating_system == "REDHAT_8_64" || var.operating_system == "RHCOS"
  }

}

##############################################################################
