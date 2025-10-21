variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
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

##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster to deploy the agent in."
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The resource group ID of the cluster."
}

variable "cluster_config_endpoint_type" {
  description = "Specify the type of endpoint to use to access the cluster configuration. Possible values: `default`, `private`, `vpe`, `link`. The `default` value uses the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
}

variable "is_vpc_cluster" {
  type        = bool
  description = "Specify true if the target cluster for the DA is a VPC cluster, false if it is classic cluster."
  default     = true
}

variable "wait_till" {
  description = "Specify the stage when Terraform should mark the cluster resource creation as completed. Supported values: `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady`, `Normal`."
  type        = string
  default     = "Normal"
}

variable "wait_till_timeout" {
  description = "Timeout for wait_till in minutes."
  type        = number
  default     = 90
}

##############################################################################
# Logs Agent variables
##############################################################################

variable "logs_agent_chart" {
  description = "The name of the Helm chart to deploy."
  type        = string
  default     = "logs-agent-helm" # Replace with the actual chart name if different
  nullable    = false
}

variable "logs_agent_chart_location" {
  description = "The location of the Logs agent helm chart."
  type        = string
  default     = "oci://icr.io/ibm-observe" # Public registry - no authentication required
  nullable    = false
}

variable "logs_agent_chart_version" {
  description = "The version of the Helm chart to deploy."
  type        = string
  default     = "1.6.3" # datasource: icr.io/ibm-observe/logs-agent-helm
  nullable    = false
}

variable "logs_agent_init_image_version" {
  description = "The version of the Logs agent init container image to deploy."
  type        = string
  default     = "1.6.3@sha256:0696d9be28088aad5ebcce26855d6de9abd7d4b0f8b98d050fb4507625ca465f" # datasource: icr.io/ibm/observe/logs-router-agent-init
  nullable    = false
}

variable "logs_agent_image_version" {
  description = "The version of the Logs agent image to deploy."
  type        = string
  default     = "1.6.3@sha256:c4c03d39002278558e7be9a7349a3408c703de788ebc7ef5846edf1f8f5e4584" # datasource: icr.io/ibm/observe/logs-router-agent
  nullable    = false
}

variable "logs_agent_name" {
  description = "The name of the Logs agent. The name is used in all Kubernetes and Helm resources in the cluster."
  type        = string
  default     = "logs-agent"
  nullable    = false
}

variable "logs_agent_namespace" {
  type        = string
  description = "The namespace where the Logs agent is deployed. The default value is `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "logs_agent_trusted_profile_id" {
  type        = string
  description = "The IBM Cloud trusted profile ID. Used only when `logs_agent_iam_mode` is set to `TrustedProfile`. The trusted profile must have an IBM Cloud Logs `Sender` role. If `logs_agent_iam_mode` is set to `TrustedProfile` and this value is not provided a new trusted profile will be created."
  default     = null
}

variable "logs_agent_tolerations" {
  description = "List of tolerations to apply to Logs agent. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/tree/main/solutions/fully-configurable/DA-types.md#configuring-logs-agent-tolerations)."
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [{
    operator = "Exists"
  }]
}

variable "logs_agent_resources" {
  description = "The resources configuration for cpu/memory/storage. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/blob/main/solutions/fully-configurable/DA-types.md#configuring-logs-agent-resources)."
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "500m"
      memory = "3Gi"
    }
    requests = {
      cpu    = "100m"
      memory = "1Gi"
    }
  }
}

variable "logs_agent_system_logs" {
  type        = list(string)
  description = "The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/logger-agent-ds-*.log`."
  default     = []
  nullable    = false
}

variable "logs_agent_exclude_log_source_paths" {
  type        = list(string)
  description = "The list of log sources to exclude. Specify the paths that the Logs agent ignores."
  default     = []
  nullable    = false
}

variable "logs_agent_selected_log_source_paths" {
  type        = list(string)
  description = "The list of specific log sources paths. Logs will only be collected from the specified log source paths."
  default     = []
  nullable    = false
}

variable "logs_agent_log_source_namespaces" {
  type        = list(string)
  description = "The list of namespaces from which logs should be forwarded by agent. When specified logs from only these namespaces will be sent by the agent."
  default     = []
  nullable    = false
}

variable "enable_annotations" {
  description = "Set to true to include pod annotations in log records. Default annotations such as pod IP address and container ID, along with any custom annotations on the pod, will be included. This can help filter logs based on pod annotations in Cloud Logs."
  type        = bool
  default     = false
}

variable "log_filters" {

  # variable type is any because filters schema is not fixed and there are many filters each having its unique fields.
  # logs-agent helm chart expects this variable to be provided in list format even if a single filter is passed.

  description = "List of additional filters to be applied on logs. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/blob/main/solutions/fully-configurable/DA-types.md#configuring-log-filters)."
  type        = any
  default     = []
}


variable "logs_agent_iam_mode" {
  type        = string
  default     = "TrustedProfile"
  description = "IAM authentication mode: `TrustedProfile` or `IAMAPIKey`. `logs_agent_iam_api_key` is required when `logs_agent_iam_mode` is set to `IAMAPIKey`."
  validation {
    error_message = "The IAM mode can only be `TrustedProfile` or `IAMAPIKey`."
    condition     = contains(["TrustedProfile", "IAMAPIKey"], var.logs_agent_iam_mode)
  }
}

variable "logs_agent_iam_api_key" {
  type        = string
  description = "The IBM Cloud API key for the Logs agent to authenticate and communicate with the IBM Cloud Logs. It is required if `logs_agent_iam_mode` is set to `IAMAPIKey`."
  sensitive   = true
  default     = null
  validation {
    condition     = !(var.logs_agent_iam_mode == "IAMAPIKey" && var.logs_agent_iam_api_key == null)
    error_message = "`logs_agent_iam_api_key` is required when `logs_agent_iam_mode` is set to `IAMAPIKey`."
  }
}

variable "logs_agent_iam_environment" {
  type        = string
  default     = "PrivateProduction"
  description = "IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`."
  validation {
    error_message = "The IAM environment can only be `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`."
    condition     = contains(["Production", "PrivateProduction", "Staging", "PrivateStaging"], var.logs_agent_iam_environment)
  }
}

variable "logs_agent_additional_metadata" {
  description = "The list of additional metadata fields to add to the routed logs. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/blob/main/solutions/fully-configurable/DA-types.md#configuring-logs-agent-additional-metadata)."
  type = list(object({
    key   = optional(string)
    value = optional(string)
  }))
  default = []
}

variable "is_ocp_cluster" {
  description = "Whether to enable creation of Security Context Constraints in Openshift. When installing on an OpenShift cluster, this setting is mandatory to configure permissions for pods within your cluster."
  type        = bool
  default     = true
}

variable "cloud_logs_ingress_endpoint" {
  description = "The host for IBM Cloud Logs ingestion. Ensure you use the ingress endpoint. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-endpoints_ingress."
  type        = string
}

variable "cloud_logs_ingress_port" {
  type        = number
  default     = 3443
  description = "The target port for the IBM Cloud Logs ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs."
  validation {
    error_message = "The Logs Routing supertenant ingestion port can only be `3443` or `443`."
    condition     = contains([3443, 443], var.cloud_logs_ingress_port)
  }
}
variable "enable_multiline" {
  description = "Enable or disable multiline log support. [Learn more](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-multiline)"
  type        = bool
  default     = false
}

variable "max_unavailable" {
  type        = string
  description = "The maximum number of pods that can be unavailable during a DaemonSet rolling update. Accepts absolute number or percentage (e.g., '1' or '10%')."
  default     = "1"
  nullable    = false
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
