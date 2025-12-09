generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
}

variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API Key"
}
EOF
}
