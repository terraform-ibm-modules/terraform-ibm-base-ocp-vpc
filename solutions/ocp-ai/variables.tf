variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api key"
  sensitive   = true
}
variable "region" {
  type        = string
  description = "Region where resources are created"
  default     = "us-south"
}
variable "cluster_name" {
  type        = string
  description = "The name that will be assigned to the provisioned cluster"
}
