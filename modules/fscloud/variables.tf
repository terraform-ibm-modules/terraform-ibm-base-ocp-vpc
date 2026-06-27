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

# Cluster Variables
variable "resource_tags" {
  type        = list(string)
  description = "Add user resource tags to the cluster to organize, track, and manage costs. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#tag-types)."
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
  description = "The COS id of an already existing COS instance to use for OpenShift internal registry storage. Only required if 'enable_registry_storage' is true."
  default     = null

  validation {
    condition     = !(var.enable_registry_storage && var.existing_cos_id == null)
    error_message = "A value for 'existing_cos_id' must be provided when 'enable_registry_storage' is set to true."
  }
}

variable "enable_registry_storage" {
  type        = bool
  description = "Set to `true` to enable IBM Cloud Object Storage for the Red Hat OpenShift internal image registry. Set to `false` only for new cluster deployments in an account that is allowlisted for this feature."
  default     = true
}

variable "kms_config" {
  type = object({
    crk_id           = string               # ID of the customer root key
    instance_id      = string               # GUID of the KMS instance
    private_endpoint = optional(bool, true) # Defaults to true to configure the KMS private service endpoint
    account_id       = optional(string)     # To attach KMS instance from another account
    wait_for_apply   = optional(bool, true) # Defaults to true so terraform will wait until the KMS is applied to the master, ready and deployed
  })
  description = "Use to attach a Key Protect or Hyper Protect Crypto Service instance to the cluster. If account_id is not provided, the current account is used. [Learn more](https://cloud.ibm.com/docs/key-protect?topic=key-protect-provision)"
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
    debug-tool = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    image-key-synchronizer = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    openshift-data-foundation = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    vpc-file-csi-driver = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    static-route = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    cluster-autoscaler = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    vpc-block-csi-driver = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    ibm-storage-operator = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
    openshift-ai = optional(object({
      version         = optional(string)
      parameters_json = optional(string)
    }))
  })
  description = "Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters and 'ibm-storage-operator' is installed by default in OCP 4.15 and later, however you can explicitly specify it here if you wish to choose a later version than the default one). For full list of all supported add-ons and versions, see https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions"
  default     = {}
}

variable "access_tags" {
  type        = list(string)
  description = "Add access management tags to the resources created to control access. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#create-access-console)."
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
    error_message = "Please set the number_of_lbs to a minimum of 1."
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

variable "network_plugin" {
  description = "The Container Network Interface (CNI) plugin for the cluster. Requires OpenShift >= 4.20. Supported values are Calico (default) and OVNKubernetes."
  type        = string
  default     = "Calico"
  nullable    = false
  validation {
    error_message = "Invalid network plugin type! Valid values are 'Calico', 'OVNKubernetes'."
    condition     = contains(["Calico", "OVNKubernetes"], var.network_plugin)
  }
}

variable "image_security_enforcement" {
  description = "Set to true to enable image security enforcement policies in a cluster. When you enable image security enforcement in your cluster, you install the open-source Portieris Kubernetes project. Then, you can create image policies to prevent pods that don't meet the policies, such as unsigned images, from running in your cluster. For more information, see the Portieris documentation (https://github.com/IBM/portieris)."
  type        = bool
  default     = false
  nullable    = false
}

##############################################################################

##############################################################
# Context-based restriction (CBR)
##############################################################

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
  description = "The context-based restrictions rule to create. Reduce the attack surface with context-based restrictions. Only one rule is allowed. [Learn more](https://cloud.ibm.com/docs/iam?topic=iam-context-restrictions-whatis)"
  default     = []
}

variable "enable_ocp_console" {
  description = "Flag to specify whether to enable or disable the OpenShift console."
  type        = bool
  default     = true
}

##############################################################
# Cluster Timeout Configuration
##############################################################

variable "cluster_delete_timeout" {
  type        = string
  description = "Timeout duration for cluster deletion operations. Specify a duration string (e.g., '2h', '30m')."
  default     = "2h"
  nullable    = false
  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.cluster_delete_timeout))
    error_message = "The cluster_delete_timeout value must be a valid duration string (e.g., '2h', '30m', '90s')."
  }
}

variable "cluster_create_timeout" {
  type        = string
  description = "Timeout duration for cluster creation operations. Specify a duration string (e.g., '3h', '45m')."
  default     = "3h"
  nullable    = false
  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.cluster_create_timeout))
    error_message = "The cluster_create_timeout value must be a valid duration string (e.g., '3h', '45m', '180s')."
  }
}

variable "cluster_update_timeout" {
  type        = string
  description = "Timeout duration for cluster update operations. Specify a duration string (e.g., '3h', '1h30m')."
  default     = "3h"
  nullable    = false
  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.cluster_update_timeout))
    error_message = "The cluster_update_timeout value must be a valid duration string (e.g., '3h', '90m', '180s')."
  }
}

variable "cluster_autoscaler_config" {
  description = "Cluster Autoscaler configuration parameters controlling scaling behavior of worker pools (scale-up/scale-down decisions, thresholds, and timing), only explicitly provided fields are applied, and unspecified fields use IKS defaults. [Learn more](https://cloud.ibm.com/docs/containers?topic=containers-cluster-scaling-install-addon-enable#ca-configmap)."

  type = object({
    coresTotal                   = optional(string)
    expander                     = optional(string)
    expendablePodsPriorityCutoff = optional(number)
    ignoreDaemonsetsUtilization  = optional(bool)
    imagePullPolicy              = optional(string)

    livenessProbeFailureThreshold = optional(number)
    livenessProbePeriodSeconds    = optional(number)
    livenessProbeTimeoutSeconds   = optional(number)

    logLevel = optional(string)

    maxBulkSoftTaintCount     = optional(number)
    maxBulkSoftTaintTime      = optional(string)
    maxFailingTime            = optional(string)
    maxGracefulTerminationSec = optional(number)
    maxInactivity             = optional(string)
    maxNodeProvisionTime      = optional(string)
    maxRetryGap               = optional(number)
    maxTotalUnreadyPercentage = optional(number)

    memoryTotal         = optional(string)
    minReplicaCount     = optional(number)
    newPodScaleUpDelay  = optional(string)
    okTotalUnreadyCount = optional(number)

    resourcesLimitsCPU      = optional(string)
    resourcesLimitsMemory   = optional(string)
    resourcesRequestsCPU    = optional(string)
    resourcesRequestsMemory = optional(string)

    retryAttempts = optional(number)

    scaleDownCandidatesPoolMinCount  = optional(number)
    scaleDownCandidatesPoolRatio     = optional(number)
    scaleDownDelayAfterAdd           = optional(string)
    scaleDownDelayAfterDelete        = optional(string)
    scaleDownDelayAfterFailure       = optional(string)
    scaleDownEnabled                 = optional(bool)
    scaleDownGPUUtilizationThreshold = optional(number)
    scaleDownNonEmptyCandidatesCount = optional(number)
    scaleDownUnneededTime            = optional(string)
    scaleDownUnreadyTime             = optional(string)
    scaleDownUtilizationThreshold    = optional(number)

    scanInterval = optional(string)

    skipNodesWithLocalStorage = optional(bool)
    skipNodesWithSystemPods   = optional(bool)

    unremovableNodeRecheckTimeout = optional(string)

    # extended fields
    maxNodeGroupBinpackingDuration = optional(string)
    maxNodesPerScaleUp             = optional(number)
    parallelDrain                  = optional(bool)
    maxScaleDownParallelism        = optional(number)
    maxDrainParallelism            = optional(number)
    nodeDeletionBatcherInterval    = optional(string)
    nodeDeleteDelayAfterTaint      = optional(string)
    enforceNodeGroupMinSize        = optional(bool)
    kubeClientBurst                = optional(number)
    kubeClientQPS                  = optional(number)
    scaleDownUnreadyEnabled        = optional(bool)
    maxPodEvictionTime             = optional(string)
    balancingIgnoreLabel           = optional(string)
    OSReservedMemoryGi             = optional(number)
    OSReservedCPUMili              = optional(number)
  })

  default = {}
}
