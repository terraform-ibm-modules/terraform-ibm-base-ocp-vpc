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
  default     = "base-ocp-mzr"
  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  type        = string
  description = "Region where resources are created"
  default     = "eu-gb"
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
    zone-2 = true
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
    zone-1 = ["10.243.0.0/23", "10.243.5.0/24"]
    zone-2 = ["10.243.64.0/23", "10.243.69.0/24"]
    zone-3 = ["10.243.128.0/23", "10.243.133.0/24"]
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
        name     = "z1-subnet-a"
        cidr     = "10.243.0.0/23"
      },
      {
        acl_name = "vpc-acl"
        name     = "z1-subnet-b"
        cidr     = "10.243.5.0/24"
      }
    ],
    zone-2 = [
      {
        acl_name = "vpc-acl"
        name     = "z2-subnet-c"
        cidr     = "10.243.64.0/23"
      },
      {
        acl_name = "vpc-acl"
        name     = "z2-subnet-d"
        cidr     = "10.243.69.0/24"
      }
    ],
    zone-3 = [
      {
        acl_name = "vpc-acl"
        name     = "z3-subnet-e"
        cidr     = "10.243.128.0/23"
      },
      {
        acl_name = "vpc-acl"
        name     = "z3-subnet-f"
        cidr     = "10.243.133.0/24"
      }
    ]
  }
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
  default = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names standard pool "standard" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
    },
    {
      subnet_prefix    = "default"
      pool_name        = "logging-worker-pool"
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      labels           = { "dedicated" : "logging-worker-pool" }
    }
  ]
  description = "List of worker pools"
}

variable "worker_pools_taints" {
  type        = map(list(object({ key = string, value = string, effect = string })))
  description = "Map of lists containing node taints by node-pool name"

  default = {
    all = []
    logging-worker-pool = [{
      key    = "dedicated"
      value  = "logging-worker-pool"
      effect = "NoExecute"
    }]
    default = []
  }
}

##############################################################################
