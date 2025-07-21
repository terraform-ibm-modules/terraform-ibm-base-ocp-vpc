
variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
  sensitive   = true
}
variable "existing_resource_group_name" {
  type        = string
  description = "Name of the existing resource group. Required if not creating new resource group"
  default     = "Default"
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
variable "prefix" {
  type        = string
  description = "The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--'). Example: `prod-0205-ocpqs`."
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
    condition     = length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}
variable "region" {
  type        = string
  description = "Region in which all the resources will be deployed. [Learn More](https://terraform-ibm-modules.github.io/documentation/#/region)."
  default     = "us-south"
}
variable "ocp_version" {
  type        = string
  description = "The version of the OpenShift cluster."
  default     = "4.17"

  validation {
    condition = anytrue([
      var.ocp_version == null,
      var.ocp_version == "default",
      var.ocp_version == "4.18",
      var.ocp_version == "4.15",
      var.ocp_version == "4.16",
      var.ocp_version == "4.17",
    ])
    error_message = "The specified ocp_version is not of the valid versions."
  }
}
variable "cluster_name" {
  type        = string
  description = "Name of new IBM Cloud OpenShift Cluster"
  default     = "ocp-qs"
}
variable "address_prefix" {
  description = "The IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes."
  type        = string
  default     = "10.10.10.0/24"
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = null
}


variable "default_worker_pool_operating_system" {
  type        = string
  description = "Provide the operating system for the worker nodes in the default worker pool. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-ai-addon-install&interface=ui#ai-min)"
  default     = "RHCOS"
}
variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the resources created by the module."
  default     = []
}

variable "size" {
  type        = string
  description = "A list of access tags to apply to the resources created by the module."
  default     = "mini"
}
