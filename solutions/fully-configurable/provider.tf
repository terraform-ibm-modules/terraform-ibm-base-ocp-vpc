########################################################################################################################
# Provider config
########################################################################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = local.vpc_region
  visibility       = var.provider_visibility
}

provider "ibm" {
  alias            = "kms"
  ibmcloud_api_key = var.ibmcloud_kms_api_key != null ? var.ibmcloud_kms_api_key : var.ibmcloud_api_key
  region           = local.cluster_kms_region
  visibility       = var.provider_visibility
}

provider "ibm" {
  alias            = "secrets_manager"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.enable_secrets_manager_integration ? module.existing_secrets_manager_instance_parser[0].region : local.vpc_region
  visibility       = var.provider_visibility
}
