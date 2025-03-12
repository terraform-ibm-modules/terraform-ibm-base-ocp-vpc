variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

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
  default = {
    "default" =[{
    "id" = "ary-subnet-1"
    "zone" = "us-south-1"
    "cidr_block" = "10.240.0.0/24"
  }]
  }
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
  default = [
  {
    "machine_type" = "bx2.8x32"
    "operating_system" = "REDHAT_8_64"
    "pool_name" = "default"
    "subnet_prefix" = "default"
    "workers_per_zone" = 2
  },
]
  validation {
    condition     = var.worker_pools[0].workers_per_zone >= 2 ? true : false 
    error_message = "The Cluster must have at least two worker nodes."
  }

  validation {
    condition     = contains(local.flavor_list,var.worker_pools[0].machine_type) ? true : false
    error_message = "All Worker nodes in the cluster must have minimum configuration as 8-core, 32GB memory."
  }
  validation {
    condition     = contains(local.os_version, var.worker_pools[0].operating_system) ? true : false
    error_message = "RHEL 9 (RHEL_9_64), RHEL 8 (REDHAT_8_64) or Red Hat Enterprise Linux CoreOS (RHCOS) are the allowed OS values."
  }

  validation {
    condition = var.worker_pools[0].pool_name == "gpu" ? contains(local.flavor_list,var.worker_pools[0].machine_type) ? true : false : true
    error_message = "All Worker nodes in the cluster must have minimum configuration as 8-core, 32GB memory."
  }

}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = null
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC instance where this cluster will be provisioned"
}


variable "addons" {
  type = object({
    openshift-ai = optional(string)
  })
  description = "Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters and 'ibm-storage-operator' is installed by default in OCP 4.15 and later, however you can explicitly specify it here if you wish to choose a later version than the default one). For full list of all supported add-ons and versions, see https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions"
  default     = {}
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details"
  default     = []
}

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision"
  validation {
    condition     = contains(local.allowed_ocp_version, var.ocp_version) ? true : false
    error_message = "OCPAI Addon Supports OpenShift cluster versions: >=4.16 <4.18 ."
  }
}
variable "disable_outbound_traffic_protection" {
  type    = bool 
  description = "outbound traffic protection"
  default = true
  validation {
    condition     = var.disable_outbound_traffic_protection == true ? true : false
    error_message = "outbound traffic protection should be disabled, if any of the OpenShift Pipelines, Node Feature Discovery, or NVIDIA GPU operators are used with OCP AI addon."
  }

}