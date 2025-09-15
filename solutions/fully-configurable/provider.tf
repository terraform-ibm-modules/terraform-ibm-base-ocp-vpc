########################################################################################################################
# Provider config
########################################################################################################################

provider "ibm" {
  ibmcloud_api_key      = var.ibmcloud_api_key
  region                = local.vpc_region
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && local.vpc_region == "ca-mon") ? "vpe" : null
}

provider "ibm" {
  alias                 = "kms"
  ibmcloud_api_key      = var.ibmcloud_kms_api_key != null ? var.ibmcloud_kms_api_key : var.ibmcloud_api_key
  region                = local.cluster_kms_region
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && local.vpc_region == "ca-mon") ? "vpe" : null
}

provider "ibm" {
  alias                 = "secrets_manager"
  ibmcloud_api_key      = var.ibmcloud_api_key
  region                = var.enable_secrets_manager_integration ? module.existing_secrets_manager_instance_parser[0].region : local.vpc_region
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && local.vpc_region == "ca-mon") ? "vpe" : null
}

provider "helm" {
  kubernetes = {
    host                   = data.ibm_container_cluster_config.cluster_config[0].host
    token                  = data.ibm_container_cluster_config.cluster_config[0].token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config[0].ca_certificate
  }
}

provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.cluster_config[0].host
  token                  = data.ibm_container_cluster_config.cluster_config[0].token
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config[0].ca_certificate
}
