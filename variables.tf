##############################################################################
# Input Variables
##############################################################################

# Resource Group Variables
variable "resource_group_id" {
  type        = string
  description = "The ID of an existing IBM Cloud resource group where the cluster is grouped."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster is provisioned."
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

variable "vpc_subnets" {
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
  validation {
    error_message = "Provide a value for minSize and maxSize while enableAutoscaling is set to true."
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
  validation {
    condition = alltrue([
      for worker_pool in var.worker_pools :
      anytrue([
        worker_pool.operating_system == local.os_rhel9,
        worker_pool.operating_system == local.os_rhel,
        worker_pool.operating_system == local.os_rhcos
      ])
    ])
    error_message = "RHEL 9 (RHEL_9_64), RHEL 8 (REDHAT_8_64) or Red Hat Enterprise Linux CoreOS (RHCOS) are the allowed OS values. RHCOS requires VPC clusters created from 4.15 onwards. Upgraded clusters from 4.14 cannot use RHCOS."
  }

  validation {
    condition = alltrue([
      for wp in var.worker_pools :
      (local.ocp_version_num == "4.14" && wp.operating_system == local.os_rhel) ||
      (local.ocp_version_num == "4.15" && contains([local.os_rhel, local.os_rhcos], wp.operating_system)) ||
      (contains(["4.16", "4.17"], local.ocp_version_num) && contains([local.os_rhel9, local.os_rhel, local.os_rhcos], wp.operating_system)) ||
      (local.ocp_version_num == "4.18" && contains([local.os_rhel9, local.os_rhcos], wp.operating_system)) ||
      (local.ocp_version_num == "4.19" && contains([local.os_rhel9, local.os_rhcos], wp.operating_system))
    ])
    error_message = "Invalid operating system for the given OCP version. Ensure the OS is compatible with the OCP version. Supported compatible OCP version and OS are v4.14: (REDHAT_8_64); v4.15: (REDHAT_8_64, RHCOS) ; v4.16 and v4.17: (REDHAT_8_64, RHCOS, RHEL_9_64); v4.18: (RHCOS, RHEL_9_64); v4.19: (RHEL_9_64, RHCOS)"
  }

  validation {
    condition = alltrue([
      for pool in var.worker_pools :
      length(regexall("^[a-z0-9]+(?:\\.[a-z0-9]+)*\\.\\d+x\\d+(?:\\.[a-z0-9]+)?$", pool.machine_type)) > 0
    ])
    error_message = "Invalid value provided for one or more machine type."
  }

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
  validation {
    condition     = var.custom_security_group_ids == null ? true : length(var.custom_security_group_ids) <= 4
    error_message = "Please provide at most 4 additional security groups."
  }
}

variable "additional_lb_security_group_ids" {
  description = "Additional security groups to add to the load balancers associated with the cluster. Ensure that the `number_of_lbs` is set to the number of LBs associated with the cluster. This comes in addition to the IBM maintained security group."
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = var.additional_lb_security_group_ids == null ? true : length(var.additional_lb_security_group_ids) <= 4
    error_message = "Please provide at most 4 additional security groups."
  }
}

variable "number_of_lbs" {
  description = "The number of LBs to associated the `additional_lb_security_group_names` security group with."
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

variable "ignore_worker_pool_size_changes" {
  type        = bool
  description = "Enable if using worker autoscaling. Stops Terraform managing worker count"
  default     = false
}

variable "ocp_version" {
  type        = string
  description = "The version of the OpenShift cluster that should be provisioned (format 4.x). If no value is specified, the current default version is used. You can also specify `default`. This input is used only during initial cluster provisioning and is ignored for updates. To prevent possible destructive changes, update the cluster version outside of Terraform."
  default     = null

  validation {
    condition = anytrue([
      var.ocp_version == null,
      var.ocp_version == "default",
      var.ocp_version == "4.14",
      var.ocp_version == "4.15",
      var.ocp_version == "4.16",
      var.ocp_version == "4.17",
      var.ocp_version == "4.18",
      var.ocp_version == "4.19",
    ])
    error_message = "The specified ocp_version is not of the valid versions."
  }
}

variable "enable_openshift_version_upgrade" {
  type        = bool
  description = "When set to true, allows Terraform to manage major OpenShift version upgrades. This is intended for advanced users who manually control major version upgrades. Defaults to false to avoid unintended drift from IBM-managed patch updates. NOTE: Enabling this on existing clusters requires a one-time terraform state migration. See [README](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/README.md#openshift-version-upgrade) for details."
  default     = false
}

variable "cluster_ready_when" {
  type        = string
  description = "The cluster is ready based on one of the following:: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady"
  default     = "IngressReady"

  validation {
    condition     = contains(["MasterNodeReady", "OneWorkerNodeReady", "Normal", "IngressReady"], var.cluster_ready_when)
    error_message = "The input variable cluster_ready_when must be one of the following: \"MasterNodeReady\", \"OneWorkerNodeReady\", \"Normal\" or \"IngressReady\"."
  }
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

variable "cos_name" {
  type        = string
  description = "Name of the COS instance to provision for OpenShift internal registry storage. New instance only provisioned if 'enable_registry_storage' is true and 'use_existing_cos' is false. Default: '<cluster_name>_cos'"
  default     = null
}

variable "use_existing_cos" {
  type        = bool
  description = "Flag indicating whether or not to use an existing COS instance for OpenShift internal registry storage. Only applicable if 'enable_registry_storage' is true"
  default     = false
}

variable "existing_cos_id" {
  type        = string
  description = "The COS id of an already existing COS instance to use for OpenShift internal registry storage. Only required if 'enable_registry_storage' and 'use_existing_cos' are true."
  default     = null

  validation {
    condition     = !(var.enable_registry_storage && var.use_existing_cos && var.existing_cos_id == null)
    error_message = "A value for 'existing_cos_id' must be provided when 'enable_registry_storage' and 'use_existing_cos' are both set to true."
  }
}

variable "enable_registry_storage" {
  type        = bool
  description = "Set to `true` to enable IBM Cloud Object Storage for the Red Hat OpenShift internal image registry. Set to `false` only for new cluster deployments in an account that is allowlisted for this feature."
  default     = true
}

variable "kms_config" {
  type = object({
    crk_id           = string
    instance_id      = string
    private_endpoint = optional(bool, true) # defaults to true
    account_id       = optional(string)     # To attach KMS instance from another account
    wait_for_apply   = optional(bool, true) # defaults to true so terraform will wait until the KMS is applied to the master, ready and deployed
  })
  description = "Use to attach a KMS instance to the cluster. If account_id is not provided, defaults to the account in use."
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

variable "disable_outbound_traffic_protection" {
  type        = bool
  description = "Whether to allow public outbound access from the cluster workers. This is only applicable for OCP 4.15 and later."
  default     = false
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

# VPC Variables
variable "vpc_id" {
  type        = string
  description = "ID of the VPC instance where this cluster is provisioned."
}

variable "verify_worker_network_readiness" {
  type        = bool
  description = "By setting this to true, a script runs kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, set this value to false."
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
  nullable    = false
  default     = {}

  validation {
    condition     = (lookup(var.addons, "openshift-ai", null) != null ? lookup(var.addons["openshift-ai"], "version", null) == null : true) || (tonumber(local.ocp_version_num) >= 4.16)
    error_message = "OCP AI add-on requires OCP version >= 4.16.0"
  }

  validation {
    condition     = (lookup(var.addons, "openshift-ai", null) != null ? lookup(var.addons["openshift-ai"], "version", null) == null : true) || alltrue([for spec in values(local.worker_specs) : spec.cpu_count >= 8 && spec.ram_count >= 32])
    error_message = "To install OCP AI add-on, all worker nodes in all pools must have at least 8-core CPU and 32GB memory."
  }

  validation {
    condition     = (lookup(var.addons, "openshift-ai", null) != null ? lookup(var.addons["openshift-ai"], "version", null) == null : true) || anytrue([for pool in var.worker_pools : lookup(local.worker_specs[pool.pool_name], "is_gpu", false)])
    error_message = "OCP AI add-on requires at least one GPU-enabled worker pool."
  }

}

variable "manage_all_addons" {
  type        = bool
  default     = false
  nullable    = false # null values are set to default value
  description = "Instructs Terraform to manage all cluster addons, even if addons were installed outside of the module. If set to 'true' this module destroys any addons that were installed by other sources."
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for cluster config access: 'default', 'private', 'vpe', 'link'. A 'default' value uses the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

variable "enable_ocp_console" {
  description = "Flag to specify whether to enable or disable the OpenShift console. If set to `null` the module does not modify the current setting on the cluster. Keep in mind that when this input is set to `true` or `false` on a cluster with private only endpoint enabled, the runtime must be able to access the private endpoint."
  type        = bool
  default     = null
  nullable    = true
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
  description = "The list of context-based restriction rules to create."
  default     = []
}

##############################################################
# Ingress Secrets Manager Integration
##############################################################

variable "enable_secrets_manager_integration" {
  type        = bool
  description = "Integrate with IBM Cloud Secrets Manager so you can centrally manage Ingress subdomain certificates and other secrets. [Learn more](https://cloud.ibm.com/docs/containers?topic=containers-secrets-mgr)"
  default     = false
  nullable    = false
  validation {
    condition     = var.enable_secrets_manager_integration ? var.existing_secrets_manager_instance_crn != null : true
    error_message = "'existing_secrets_manager_instance_crn' should be provided if setting 'enable_secrets_manager_integration' to true."
  }
}

variable "existing_secrets_manager_instance_crn" {
  type        = string
  description = "CRN of the Secrets Manager instance where Ingress certificate secrets are stored. If 'enable_secrets_manager_integration' is set to true then this value is required."
  default     = null
}

variable "secrets_manager_secret_group_id" {
  type        = string
  description = "Secret group ID where Ingress secrets are stored in the Secrets Manager instance."
  default     = null
}

variable "skip_ocp_secrets_manager_iam_auth_policy" {
  type        = bool
  description = "To skip creating auth policy that allows OCP cluster 'Manager' role access in the existing Secrets Manager instance for managing ingress certificates."
  default     = false
}

variable "skip_cluster_apikey_creation" {
  type        = bool
  description = "Set to true to skip explicit creation of the `containers-kubernetes-key` for the given region and resource group. You can set this to false if you plan to manually create this key, or if you want to allow the cluster creation process to create it. Please be aware that it may take multiple apply attempts when allowing the cluster creation process to create it it before it will be successful."
  default     = false
}
