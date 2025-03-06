########################################################################################################################
# Input variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api key"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
  default = "dev"
}

# Resource Group Variables
variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of a new or the existing resource group to provision the cluster. If a prefix input variable is passed, it is prefixed to the value in the `<prefix>-value` format."
}

variable "region" {
  type        = string
  description = "Region where resources are created"
}

variable "use_private_endpoint" {
  type        = bool
  description = "Set this to true to force all api calls to use the IBM Cloud private endpoints."
  default     = false
}

variable "resource_tags" {
  type        = list(string)
  description = "Metadata labels describing this cluster deployment, i.e. test"
  default     = []
}

variable "cluster_name" {
  type        = string
  description = "The name of the new IBM Cloud OpenShift Cluster. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "allow_default_worker_pool_replacement" {
  type        = bool
  description = "Set to true to allow the module to recreate a default worker pool. Only use in the case where you are getting an error indicating that the default worker pool cannot be replaced on apply. Once the default worker pool is handled separately, if you wish to make any change to the default worker pool which requires the re-creation of the default pool set this variable to true."
  default     = false
  nullable    = false
}

variable "worker_pools_taints" {
  type        = map(list(object({ key = string, value = string, effect = string })))
  description = "Optional, Map of lists containing node taints by node-pool name"
  default     = null
}

variable "attach_ibm_managed_security_group" {
  description = "Specify whether to attach the IBM-defined default security group (whose name is kube-<clusterid>) to all worker nodes. Only applicable if `custom_security_group_ids` is set."
  type        = bool
  default     = true
}

variable "custom_security_group_ids" {
  description = "Security groups to add to all worker nodes. This comes in addition to the IBM maintained security group if `attach_ibm_managed_security_group` is set to true. If this variable is set, the default VPC security group is NOT assigned to the worker nodes."
  type        = list(string)
  default     = null
}

variable "additional_lb_security_group_ids" {
  description = "Additional security groups to add to the load balancers associated with the cluster. Ensure that the `number_of_lbs` is set to the number of LBs associated with the cluster. This comes in addition to the IBM maintained security group."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "number_of_lbs" {
  description = "The number of LBs to associated the `additional_lb_security_group_names` security group with."
  type        = number
  default     = 1
  nullable    = false
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

variable "ignore_worker_pool_size_changes" {
  type        = bool
  description = "Enable if using worker autoscaling. Stops Terraform managing worker count"
  default     = false
}

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision"
}

variable "cluster_ready_when" {
  type        = string
  description = "The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady"
  default     = "IngressReady"
}

variable "disable_public_endpoint" {
  type        = bool
  description = "Whether access to the public service endpoint is disabled when the cluster is created. Does not affect existing clusters. You can't disable a public endpoint on an existing cluster, so you can't convert a public cluster to a private cluster. To change a public endpoint to private, create another cluster with this input set to `true`."
  default     = false
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

variable "number_worker_nodes" {
  type        = number
  description = "The number of workers to create in the cluster"
  default     = 2
}

variable "machine_type" {
  type        = string
  description = "Worker node machine type. Use 'ibmcloud ks flavors --zone <zone>' to retrieve the list."
  default     = "bx2.4x16"
}

variable "operating_system" {
  type        = string
  description = "Allowed OS values are RHEL_9 (RHEL_9_64), RHEL 8 (REDHAT_8_64) or Red Hat Enterprise Linux CoreOS (RHCOS). RHCOS requires VPC clusters created from 4.15 onwards. Upgraded clusters from 4.14 cannot use RHCOS."
  default     = "RHEL_9_64"
}

variable "disable_outbound_traffic_protection" {
  type        = bool
  description = "Whether to allow public outbound access from the cluster workers. This is only applicable for OCP 4.15 and later."
  default     = true
}

variable "pod_subnet_cidr" {
  type        = string
  description = "Specify a custom subnet CIDR to provide private IP addresses for pods. The subnet must have a CIDR of at least `/23` or larger. Default value is `172.30.0.0/16` when the variable is set to `null`."
  default     = null
}

variable "service_subnet_cidr" {
  type        = string
  description = "Specify a custom subnet CIDR to provide private IP addresses for services. The subnet must be at least `/24` or larger. Default value is `172.21.0.0/16` when the variable is set to `null`."
  default     = null
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
  nullable    = false
  default     = {}
}

variable "manage_all_addons" {
  type        = bool
  default     = false
  nullable    = false # null values are set to default value
  description = "Instructs Terraform to manage all cluster addons, even if addons were installed outside of the module. If set to 'true' this module will destroy any addons that were installed by other sources."
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
}

variable "enable_ocp_console" {
  description = "Flag to specify whether to enable or disable the OpenShift console."
  type        = bool
  default     = true
}


##############################################################
# KMS Config
##############################################################

variable "crk_id" {
  description = "The ID of the cluster root key to use for cluster encryption."
  type        = string
  default     = null

  validation {
    condition     = var.crk_id != null ? var.instance_id != null : true
    error_message = "When providing a `crk_id`, you must also provide an `instance_id`."
  }
}

variable "instance_id" {
  type        = string
  description = "The ID of the KMS instance to use for cluster encryption."
  default     = null

  validation {
    condition     = var.instance_id != null ? var.crk_id != null : true
    error_message = "When providing an `instance_id`, you must also provide a `crk_id`."
  }
}

variable "private_endpoint" {
  type        = bool
  description = "Whether to use a private endpoint for KMS communication. Defaults to true."
  default     = false
}

variable "account_id" {
  type        = string
  description = "The account ID to attach KMS instance from. If not provided, defaults to the account in use."
  default     = null
}

variable "wait_for_apply" {
  type        = bool
  description = "Whether Terraform should wait until the KMS is applied to the master, ready and deployed. Defaults to true."
  default     = true
}


variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module."
  default     = []
}

variable "existing_vpc_id" {
  type        = string
  description = "Id of the VPC instance where this cluster will be provisioned"
}

variable "existing_cos_instance_crn" {
  type        = string
  description = "The COS id of an already existing COS instance to use for OpenShift internal registry storage."
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "cbr_rules" {
  type = list(object({
    description = string
    account_id  = string
    rule_contexts = list(object({
      attributes = optional(list(object({
        name  = string
        value = string
    }))) }))
    enforcement_mode = string
    tags = optional(list(object({
      name  = string
      value = string
    })), [])
    operations = optional(list(object({
      api_types = list(object({
        api_type_id = string
      }))
    })))
  }))
  description = "The list of context-based restriction rules to create."
  default     = []
}
