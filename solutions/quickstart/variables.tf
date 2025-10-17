
variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
  sensitive   = true
}

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources."
  default     = "Default"
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "prefix" {
  type        = string
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to null or an empty string. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."
  nullable    = true
  validation {
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }
  validation {
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "region" {
  type        = string
  description = "Region in which all the resources will be deployed. [Learn More](https://terraform-ibm-modules.github.io/documentation/#/region)."
  default     = "us-south"
}

variable "openshift_version" {
  type        = string
  description = "Version of the OpenShift cluster to provision."
  default     = null
}

variable "cluster_name" {
  type        = string
  description = "The name of the new IBM Cloud OpenShift Cluster. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "openshift-qs"
}


variable "address_prefix" {
  description = "The IP range that defines a certain location for the VPC. Use only with manual address prefixes."
  type        = string
  default     = "10.10.10.0/24"
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning."
  default     = null
}


variable "default_worker_pool_operating_system" {
  type        = string
  description = "The operating system installed on the worker nodes. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-flavors)."
  default     = "RHEL_9_64"
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module."
  default     = []
}

variable "size" {
  type        = string
  description = "Defines the cluster size configuration. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/solutions/quickstart/DA_docs.md)."
  default     = "mini"
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
