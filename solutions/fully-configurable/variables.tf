########################################################################################################################
# Input variables
########################################################################################################################

##############################################################
# General Configuration
##############################################################
variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api key."
  sensitive   = true
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to null or an empty string. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources. [Learn more](https://cloud.ibm.com/docs/account?topic=account-rgs&interface=ui#create_rgs) about how to create a resource group."
  default     = "Default"
}

variable "cluster_resource_tags" {
  type        = list(string)
  description = "Metadata labels describing this cluster deployment, i.e. test."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module."
  default     = []
}

##############################################################
# Cluster Related
##############################################################

variable "cluster_name" {
  type        = string
  description = "The name of the new IBM Cloud OpenShift Cluster. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "cluster"
}

variable "openshift_version" {
  type        = string
  description = "Version of the OpenShift cluster to provision."
  default     = null
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning."
  default     = null
}

variable "cluster_ready_when" {
  type        = string
  description = "The cluster is ready based on one of the following:: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady."
  default     = "IngressReady"
}

variable "enable_ocp_console" {
  description = "Flag to specify whether to enable or disable the OpenShift console. If set to `null` the module does not modify the current setting on the cluster. Keep in mind that when this input is set to `true` or `false` on a cluster with private only endpoint enabled, the runtime must be able to access the private endpoint."
  type        = bool
  default     = null
  nullable    = true
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
  description = "Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters and 'ibm-storage-operator' is installed by default in OCP 4.15 and later, however you can explicitly specify it here if you wish to choose a later version than the default one). [Check supported addons and versions here](https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions). [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/solutions/fully-configurable/DA_docs.md#options-with-addons)"
  nullable    = false
  default     = {}
}

variable "manage_all_addons" {
  type        = bool
  default     = false
  nullable    = false
  description = "Instructs deployable architecture to manage all cluster addons, even if addons were installed outside of the module. If set to 'true' this deployable architecture destroys any addons that were installed by other sources."
}

variable "worker_pools_taints" {
  type        = map(list(object({ key = string, value = string, effect = string })))
  description = "Optional, Map of lists containing node taints by node-pool name. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/solutions/fully-configurable/DA_docs.md#options-with-worker-pools-taints)"
  default     = null
}

variable "ignore_worker_pool_size_changes" {
  type        = bool
  description = "Enable if using worker autoscaling. Stops Terraform managing worker count."
  default     = false
}

variable "allow_default_worker_pool_replacement" {
  type        = bool
  description = "Set to true to allow the module to recreate a default worker pool. Only use in the case where you are getting an error indicating that the default worker pool cannot be replaced on apply. Once the default worker pool is handled separately, if you wish to make any change to the default worker pool which requires the re-creation of the default pool set this variable to true."
  default     = false
  nullable    = false
}

variable "default_worker_pool_machine_type" {
  type        = string
  description = "The machine type for worker nodes.[Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors)"
  default     = "bx2.4x16"
  validation {
    condition     = length(regexall("^[a-z0-9]+(?:\\.[a-z0-9]+)*\\.\\d+x\\d+(?:\\.[a-z0-9]+)?$", var.default_worker_pool_machine_type)) > 0
    error_message = "Invalid value provided for the machine type."
  }
}

variable "default_worker_pool_workers_per_zone" {
  type        = number
  description = "Number of worker nodes in each zone of the cluster."
  default     = 1

  validation {
    condition     = can(regex("^[1-9][0-9]*$", var.default_worker_pool_workers_per_zone))
    error_message = "Worker count per zone must be greater than 0."
  }
}

variable "default_worker_pool_operating_system" {
  type        = string
  description = "The operating system installed on the worker nodes. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors)"
  default     = "RHCOS"
}

variable "default_worker_pool_labels" {
  type        = map(string)
  description = "A set of key-value labels assigned to the worker pool for identification. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/solutions/fully-configurable/DA_docs.md#default-worker-pool-labels)"
  default     = {}
}

variable "enable_autoscaling_for_default_pool" {
  type        = bool
  description = "Set `true` to enable automatic scaling of worker based on workload demand."
  default     = false
}

variable "default_pool_minimum_number_of_nodes" {
  type        = number
  description = "The minimum number of worker nodes allowed in the pool, ensuring at least one worker is always running."
  default     = 1
}

variable "default_pool_maximum_number_of_nodes" {
  type        = number
  description = "The maximum number of worker nodes allowed in the pool, preventing the pool from exceeding three workers."
  default     = 3
}

variable "additional_security_group_ids" {
  type        = list(string)
  description = "A list of security group IDs that are attached to the worker nodes for additional network security controls."
  default     = []
}

variable "additional_worker_pools" {
  type = list(object({
    vpc_subnets = optional(list(object({
      id         = string
      zone       = string
      cidr_block = string
    })), [])
    pool_name                     = string
    machine_type                  = string
    workers_per_zone              = number
    operating_system              = string
    labels                        = optional(map(string))
    minSize                       = optional(number)
    secondary_storage             = optional(string)
    maxSize                       = optional(number)
    enableAutoscaling             = optional(bool)
    additional_security_group_ids = optional(list(string))
  }))
  description = "List of additional worker pools. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/solutions/fully-configurable/DA_docs.md#options-with-worker-pools)"
  default     = []
}

##############################################################
# COS Related
##############################################################

variable "existing_cos_instance_crn" {
  type        = string
  description = "The CRN of an already existing Object Storage instance to use for OpenShift internal registry storage."

  validation {
    condition = anytrue([
      can(regex("^crn:v\\d:(.*:){2}cloud-object-storage:(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_cos_instance_crn))
    ])
    error_message = "The value provided for 'existing_cos_instance_crn' is not valid."
  }
}

##############################################################
# Network Related
##############################################################

variable "existing_vpc_crn" {
  type        = string
  description = "The CRN of an existing VPC. If the user provides only the `existing_vpc_crn` the default worker pool is provisioned across all the subnets in the VPC."

  validation {
    condition = anytrue([
      can(regex("^crn:v\\d:(.*:){2}is:(.*:)([aos]\\/[\\w_\\-]+)::vpc:[0-9a-z]{4}-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.existing_vpc_crn))
    ])
    error_message = "The value provided for 'existing_vpc_crn' is not valid."
  }
}

variable "existing_subnet_ids" {
  type        = list(string)
  description = "The list of IDs of existing subnets where the default worker pool nodes of the cluster are provisioned."
  default     = []
}

variable "use_private_endpoint" {
  type        = bool
  description = "Set this to true to force all API calls to use the IBM Cloud private endpoints."
  default     = true
}

variable "allow_public_access_to_cluster_management" {
  type        = bool
  description = "Set to true to access the cluster through a public cloud service endpoint. [Learn More](https://cloud.ibm.com/docs/openshift?topic=openshift-access_cluster)."
  default     = true
}

variable "allow_outbound_traffic" {
  type        = bool
  description = "Set to true to allow public outbound access from the cluster workers."
  default     = true
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for cluster config access: 'default', 'private', 'vpe', 'link'. A 'default' value uses the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false
}

variable "verify_worker_network_readiness" {
  type        = bool
  description = "By setting this to true, a script runs kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, set this value to false."
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

variable "custom_security_group_ids" {
  description = "Security groups to add to all worker nodes. This comes in addition to the IBM maintained security group if `attach_ibm_managed_security_group` is set to true. If this variable is set, the default VPC security group is NOT assigned to the worker nodes."
  type        = list(string)
  default     = null
}

variable "attach_ibm_managed_security_group" {
  description = "Specify whether to attach the IBM-defined default security group (whose name is kube-<clusterid>) to all worker nodes. Only applicable if `custom_security_group_ids` is set."
  type        = bool
  default     = true
}

variable "additional_lb_security_group_ids" {
  description = "List of additional security group IDs to add to the load balancers associated with the cluster. Ensure that the `number_of_lbs` variable is set to the number of Load Balancers associated with the cluster. This comes in addition to the IBM maintained security group."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "number_of_lbs" {
  description = "The total number of Load Balancers in the cluster that should be associated with the security groups defined in `additional_lb_security_group_ids` variable."
  type        = number
  default     = 1
  nullable    = false
}

variable "additional_vpe_security_group_ids" {
  description = "Additional security groups to add to all existing load balancers. This comes in addition to the IBM maintained security group. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/solutions/fully-configurable/DA_docs.md#options-with-additional-vpe-security-group-ids)"
  type = object({
    master   = optional(list(string), [])
    registry = optional(list(string), [])
    api      = optional(list(string), [])
  })
  default = {}
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are `public`, `private`, or `public-and-private`."
  }
}

##############################################################
# KMS Related
##############################################################
variable "kms_encryption_enabled_cluster" {
  description = "Set to true to enable KMS encryption for the cluster's Object Storage bucket. When set to true, a value must be passed for either `existing_cluster_kms_key_crn` or `existing_kms_instance_crn`."
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = var.existing_kms_instance_crn != null ? var.kms_encryption_enabled_cluster : true
    error_message = "If passing a value for 'existing_kms_instance_crn', you should set 'kms_encryption_enabled_cluster' to true."
  }

  validation {
    condition     = var.existing_cluster_kms_key_crn != null ? var.kms_encryption_enabled_cluster : true
    error_message = "If passing a value for 'existing_cluster_kms_key_crn', you should set 'kms_encryption_enabled_cluster' to true."
  }

  validation {
    condition     = var.kms_encryption_enabled_cluster ? ((var.existing_cluster_kms_key_crn != null || var.existing_kms_instance_crn != null) ? true : false) : true
    error_message = "Either 'existing_cluster_kms_key_crn' or 'existing_kms_instance_crn' is required if 'kms_encryption_enabled_cluster' is set to true."
  }
}

variable "existing_kms_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing KMS instance (Hyper Protect Crypto Services or Key Protect). If the KMS instance is in different account you must also provide a value for `ibmcloud_kms_api_key`."

  validation {
    condition = anytrue([
      can(regex("^crn:v\\d:(.*:){2}(kms|hs-crypto):(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_kms_instance_crn)),
      var.existing_kms_instance_crn == null,
    ])
    error_message = "The provided KMS instance CRN in the input 'existing_kms_instance_crn' is not valid."
  }
}

variable "existing_cluster_kms_key_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing KMS key to use for encrypting the Object Storage of the Cluster. If no value is set for this variable, specify a value for `existing_kms_instance_crn` variable to create a key ring and key."

  validation {
    condition = anytrue([
      can(regex("^crn:v\\d:(.*:){2}(kms|hs-crypto):(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:key:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.existing_cluster_kms_key_crn)),
      var.existing_cluster_kms_key_crn == null,
    ])
    error_message = "The provided KMS key CRN in the input 'existing_cluster_kms_key_crn' is not valid."
  }

  validation {
    condition     = var.existing_cluster_kms_key_crn != null ? var.existing_kms_instance_crn == null : true
    error_message = "A value should not be passed for 'existing_kms_instance_crn' when passing an existing key value using the 'existing_cluster_kms_key_crn' input."
  }

}

variable "kms_endpoint_type" {
  type        = string
  description = "The endpoint for communicating with the KMS instance. Possible values: `public`, `private`. Applies only if `kms_encryption_enabled_cluster` is true"
  default     = "private"
  nullable    = false
  validation {
    condition     = can(regex("^(public|private)$", var.kms_endpoint_type))
    error_message = "The kms_endpoint_type value must be 'public' or 'private'."
  }
}

variable "cluster_kms_key_ring_name" {
  type        = string
  default     = "cluster-key-ring"
  description = "The name of the key ring to be created for the cluster's Object Storage bucket encryption key. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "cluster_kms_key_name" {
  type        = string
  default     = "cluster-key"
  description = "The name of the key to be created for the cluster's Object Storage bucket encryption. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "ibmcloud_kms_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a root key and key ring in the key management service (KMS) instance for the cluster. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the KMS instance in `existing_kms_instance_crn` is in an account that is different from the cluster's account. Leave this input empty if both the cluster and the KMS instance are in the same account."
  sensitive   = true
  default     = null
}

variable "kms_encryption_enabled_boot_volume" {
  type        = bool
  description = "Set this to true to control the encryption keys used to encrypt the data that for the block storage volumes for VPC. If set to false, the data is encrypted by using randomly generated keys. For more info on encrypting block storage volumes, see https://cloud.ibm.com/docs/vpc?topic=vpc-creating-instances-byok"
  default     = false
  nullable    = false

  validation {
    condition     = var.existing_kms_instance_crn != null ? var.kms_encryption_enabled_boot_volume || var.kms_encryption_enabled_cluster : true
    error_message = "If passing a value for 'existing_kms_instance_crn', you should set 'kms_encryption_enabled_boot_volume' to true."
  }

  validation {
    condition     = var.existing_boot_volume_kms_key_crn != null ? var.kms_encryption_enabled_boot_volume : true
    error_message = "If passing a value for 'existing_boot_volume_kms_key_crn', you should set 'kms_encryption_enabled_boot_volume' to true."
  }

  validation {
    condition     = var.kms_encryption_enabled_boot_volume ? ((var.existing_boot_volume_kms_key_crn != null || var.existing_kms_instance_crn != null) ? true : false) : true
    error_message = "Either 'existing_boot_volume_kms_key_crn' or 'existing_kms_instance_crn' is required if 'kms_encryption_enabled_boot_volume' is set to true."
  }
}

variable "existing_boot_volume_kms_key_crn" {
  type        = string
  default     = null
  description = "The CRN of an existing KMS key to use to encrypt the the block storage volumes for VPC. If no value is set for this variable, specify a value for either the `existing_kms_instance_crn` variable to create a key ring and key."

  validation {
    condition = anytrue([
      can(regex("^crn:v\\d:(.*:){2}(kms|hs-crypto):(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:key:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.existing_boot_volume_kms_key_crn)),
      var.existing_boot_volume_kms_key_crn == null,
    ])
    error_message = "The provided KMS key CRN in the input 'existing_boot_volume_kms_key_crn' is not valid."
  }
}

variable "boot_volume_kms_key_ring_name" {
  type        = string
  default     = "boot-volume-key-ring"
  description = "The name for the key ring created for the block storage volumes key. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

variable "boot_volume_kms_key_name" {
  type        = string
  default     = "boot-volume-key"
  description = "The name for the key created for the block storage volumes. Applies only if not specifying an existing key. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
}

##############################################################
# CBR Related
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
  description = "The list of context-based restriction rules to create. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/solutions/fully-configurable/DA_docs.md#options-with-cbr)"
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

  validation {
    condition = anytrue([
      can(regex("^crn:v\\d:(.*:){2}secrets-manager:(.*:)([aos]\\/[\\w_\\-]+):[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_secrets_manager_instance_crn)),
      var.existing_secrets_manager_instance_crn == null,
    ])
    error_message = "The value provided for 'existing_secrets_manager_instance_crn' is not valid."
  }
}

variable "secrets_manager_secret_group_id" {
  type        = string
  description = "Secret group ID where Ingress secrets are stored in the Secrets Manager instance. If 'enable_secrets_manager_integration' is set to true and 'secrets_manager_secret_group_id' is not provided, a new group will be created with the same name as cluster_id."
  default     = null

  validation {
    condition = anytrue([
      can(regex("[a-fA-F0-9]{8}-([a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}", var.secrets_manager_secret_group_id)),
      var.secrets_manager_secret_group_id == null,
    ])
    error_message = "The value provided for 'secrets_manager_secret_group_id' is not valid."
  }
}

variable "secrets_manager_endpoint_type" {
  type        = string
  description = "The type of endpoint (public or private) to connect to the Secrets Manager API. The Terraform provider uses this endpoint type to interact with the Secrets Manager API."
  default     = "private"
  validation {
    condition     = contains(["public", "private"], var.secrets_manager_endpoint_type)
    error_message = "The specified service endpoint is not a valid selection!"
  }
}

variable "skip_ocp_secrets_manager_iam_auth_policy" {
  type        = bool
  description = "To skip creating auth policy that allows OCP cluster 'Manager' role access in the existing Secrets Manager instance for managing ingress certificates."
  default     = false
}

##############################################################
# Kube Audit
##############################################################

variable "enable_kube_audit" {
  type        = bool
  description = "Kubernetes audit logging provides a chronological record of operations performed on the cluster, including by users, administrators, and system components. It is useful for compliance, and security monitoring. Set true to enable kube audit by default. [Learn more](https://cloud.ibm.com/docs/containers?topic=containers-health-audit#audit-api-server)"
  default     = true
}

variable "audit_log_policy" {
  type        = string
  description = "Specify the amount of information that is logged to the API server audit logs by choosing the audit log policy profile to use. Supported values are `default` and `WriteRequestBodies`."
  default     = "default"

  validation {
    error_message = "Invalid Audit log policy Type! Valid values are 'default' or 'WriteRequestBodies'"
    condition     = contains(["default", "WriteRequestBodies"], var.audit_log_policy)
  }
}

variable "audit_namespace" {
  type        = string
  description = "The name of the namespace where log collection service and a deployment will be created."
  default     = "ibm-kube-audit"
}

variable "audit_deployment_name" {
  type        = string
  description = "The name of log collection deployment and service."
  default     = "ibmcloud-kube-audit"
}

variable "audit_webhook_listener_image" {
  type        = string
  description = "The audit webhook listener image reference in the format of `[registry-url]/[namespace]/[image]`. This solution uses the `icr.io/ibm/ibmcloud-kube-audit-to-ibm-cloud-logs` image to forward logs to IBM Cloud Logs. This image is for demonstration purposes only. For a production solution, configure and maintain your own log forwarding image."
  default     = "icr.io/ibm/ibmcloud-kube-audit-to-ibm-cloud-logs"
}

variable "audit_webhook_listener_image_tag_digest" {
  type        = string
  description = "The tag or digest for the audit webhook listener image to deploy. If changing the value, ensure it is compatible with `audit_webhook_listener_image`."
  default     = "latest@sha256:f7650c12b730ba2459816c3574bb1d5b8e04418396b30417a564e0d0e1757253"
}
