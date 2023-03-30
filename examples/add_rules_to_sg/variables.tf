##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "ibmcloud_access_tags_api_key" {
  type        = string
  description = "Only required for attaching access tags to resources created by the root module, set via environment variable TF_VAR_ibmcloud_access_tags_api_key"
  sensitive   = true
  default     = null
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

variable "access_tags" {
  type        = list(string)
  description = "Optional list of access tags to be added to the created cluster"
  default     = ["geretain-dev:permanent-test-tag-1"]
}

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision"
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
  }))
  description = "List of worker pools."
  default = [
    {
      subnet_prefix    = "zone-1"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names standard pool "standard" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
    },
    {
      subnet_prefix    = "zone-2"
      pool_name        = "zone-2"
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
    }
  ]
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

##############################################################################
# Security Groups
##############################################################################

variable "sg_rules_vpc" {
  description = "List of security group rules to be added to the kube-<vpcid> security group"

  default = [
    { name = "allow-port-8080", direction = "inbound", tcp = { port_max = 8080, port_min = 8080 }, remote = "10.10.10.0/24" },
    { name = "allow-port-443", direction = "inbound", tcp = { port_max = 443, port_min = 443 }, remote = "10.10.10.0/24" },
    { name = "udp-range", direction = "inbound", udp = { port_max = 30103, port_min = 30103 }, remote = "10.10.10.0/24" },
  ]

  type = list(
    object({
      name      = string
      direction = string
      remote    = string
      tcp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = (var.sg_rules_vpc == null || length(var.sg_rules_vpc) == 0) ? true : length(distinct(
      # Return false if direction is not valid
      flatten([for rule in var.sg_rules_vpc : false if !contains(["inbound", "outbound"], rule.direction)])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = (var.sg_rules_vpc == null || length(var.sg_rules_vpc) == 0) ? true : length(distinct(
      # Return false if rule name is not valid
      flatten([for rule in var.sg_rules_vpc : false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))])
    )) == 0
  }
}

variable "sg_rules_cluster" {
  description = "List of security group rules to be added to the kube-<clusterid> security group"

  default = [
    { name = "allow-port-8080", direction = "inbound", tcp = { port_max = 8080, port_min = 8080 }, remote = "10.10.10.0/24" },
    { name = "allow-port-443", direction = "inbound", tcp = { port_max = 443, port_min = 443 }, remote = "10.10.10.0/24" },
    { name = "udp-range", direction = "inbound", udp = { port_max = 30103, port_min = 30103 }, remote = "10.10.10.0/24" },
  ]

  type = list(
    object({
      name      = string
      direction = string
      remote    = string
      tcp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = (var.sg_rules_cluster == null || length(var.sg_rules_cluster) == 0) ? true : length(distinct(
      # Return false if direction is not valid
      flatten([for rule in var.sg_rules_cluster : false if !contains(["inbound", "outbound"], rule.direction)])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = (var.sg_rules_cluster == null || length(var.sg_rules_cluster) == 0) ? true : length(distinct(
      # Return false if rule name is not valid
      flatten([for rule in var.sg_rules_cluster : false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))])
    )) == 0
  }
}
##############################################################################
