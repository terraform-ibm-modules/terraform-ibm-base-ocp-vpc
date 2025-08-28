##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to use, set via environment variable TF_VAR_ibmcloud_api_key"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  type        = string
  description = "Name of the target IBM Cloud OpenShift Cluster"
}
