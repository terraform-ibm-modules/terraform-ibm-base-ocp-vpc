##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "base-ocp-std"
  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  type        = string
  description = "Region where resources are created"
  default     = "us-south"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision"
  default     = null
}

variable "primary_existing_hpcs_instance_guid" {
  description = "The GUID of the Hyper Protect Crypto service in which the key specified in var.hpcs_key_crn is coming from, used by the COS instance"
  type        = string
}

variable "secondary_existing_hpcs_instance_guid" {
  description = "The GUID of the Hyper Protect Crypto service in which the key specified in var.hpcs_key_crn is coming from, used by the COS instance"
  type        = string
}

variable "primary_hpcs_key_crn" {
  description = "CRN of the Hyper Protect Crypto service to use to encrypt the data in the COS Bucket"
  type        = string
}

variable "secondary_hpcs_key_crn" {
  description = "CRN of the Hyper Protect Crypto service to use to encrypt the data in the COS Bucket"
  type        = string
}

variable "hpcs_instance_guid" {
  type        = string
  description = "The GUID of the Hyper Protect Crypto service to provision the encryption keys"

}

variable "hpcs_key_crn_cluster" {
  description = "CRN of the Hyper Protect Crypto service to use to encrypt the cluster boot volume"
  type        = string
}

variable "hpcs_key_crn_worker_pool" {
  description = "CRN of the Hyper Protect Crypto service to use to encrypt the worker pool boot volumes"
  type        = string
}
variable "existing_at_instance_crn" {
  type        = string
  description = "Optionally pass an existing activity tracker instance CRN to use in the example. If not passed, a new instance will be provisioned"
  default     = null
}

variable "worker_pools" {
  type = list(object({
    subnet_prefix     = string
    pool_name         = string
    machine_type      = string
    workers_per_zone  = number
    resource_group_id = optional(string)
    labels            = optional(map(string))
    boot_volume_encryption_kms_config = optional(object({
      crk             = string
      kms_instance_id = string
      kms_account_id  = optional(string)
    }))
  }))
  description = "List of worker pools."
  default     = []
}

##############################################################################
# VPC variables
##############################################################################

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  default     = "management"
}

variable "public_gateway" {
  description = "Create a public gateway in any of the three zones with `true`."
  type = object({
    zone-1 = optional(bool)
    zone-2 = optional(bool)
    zone-3 = optional(bool)
  })
  default = {
    zone-1 = true
    zone-2 = false
    zone-3 = false
  }
}

variable "addresses" {
  description = "OPTIONAL - IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes"
  type = object({
    zone-1 = optional(list(string))
    zone-2 = optional(list(string))
    zone-3 = optional(list(string))
  })
  default = {
    zone-1 = ["10.10.10.0/24"]
    zone-2 = ["10.20.10.0/24"]
    zone-3 = ["10.30.10.0/24"]
  }
}

variable "subnets" {
  description = "List of subnets for the vpc. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total ipv4 addressess. Public gateways will be enabled only in zones where a gateway has been created"
  type = object({
    zone-1 = list(object({
      acl_name       = string
      name           = string
      cidr           = string
      public_gateway = optional(bool)
    }))
    zone-2 = list(object({
      acl_name       = string
      name           = string
      cidr           = string
      public_gateway = optional(bool)
    }))
    zone-3 = list(object({
      acl_name       = string
      name           = string
      cidr           = string
      public_gateway = optional(bool)
    }))
  })

  default = {
    zone-1 = [
      {
        acl_name = "vpc-acl"
        name     = "zone-1"
        cidr     = "10.10.10.0/24"
      }
    ],
    zone-2 = [
      {
        acl_name = "vpc-acl"
        name     = "zone-2"
        cidr     = "10.20.10.0/24"
      }
    ],
    zone-3 = [
      {
        acl_name = "vpc-acl"
        name     = "zone-3"
        cidr     = "10.30.10.0/24"
      }
    ]
  }
}

variable "verify_worker_network_readiness" {
  type        = bool
  description = "By setting this to true, a script will run kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, this should be set to false."
  default     = false
}

##############################################################################
