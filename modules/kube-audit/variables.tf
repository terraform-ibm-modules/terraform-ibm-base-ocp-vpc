##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster to deploy the log collection service in."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster is provisioned."
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The resource group ID of the cluster."
}

variable "wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal`"
  type        = string
  default     = "Normal"

  validation {
    error_message = "`wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` or `Normal`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady",
      "Normal"
    ], var.wait_till)
  }
}

variable "wait_till_timeout" {
  description = "Timeout for wait_till in minutes."
  type        = number
  default     = 90
}

variable "use_private_endpoint" {
  type        = bool
  description = "Set this to true to force all api calls to use the IBM Cloud private endpoints."
  default     = false
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
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
  description = "The name of log collection deployement and service."
  default     = "ibmcloud-kube-audit"
}

variable "audit_webhook_listener_image" {
  type        = string
  description = "The audit webhook listener image reference in the format of `[registry-url]/[namespace]/[image]`.The sub-module uses the `icr.io/ibm/ibmcloud-kube-audit-to-ibm-cloud-logs` image to forward logs to IBM Cloud Logs. This image is for demonstration purposes only. For a production solution, configure and maintain your own log forwarding image."
  default     = "icr.io/ibm/ibmcloud-kube-audit-to-ibm-cloud-logs"
}

variable "audit_webhook_listener_image_digest" {
  type        = string
  description = "An image digest in the format `sha256:xxxxx...` can also be specified. If no value is passed, latest image is used."
  default     = null
  validation {
    condition     = var.audit_webhook_listener_image_digest == null || can(regex("^sha256:", var.audit_webhook_listener_image_digest))
    error_message = "If provided, the value of audit_webhook_listener_image_digest must start with 'sha256:'."
  }
}
