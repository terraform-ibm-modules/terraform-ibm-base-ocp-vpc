########################################################################################################################
# Terraform providers
########################################################################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

provider "helm" {
  alias = "helm_cluster_1"
  kubernetes {
    host                   = data.ibm_container_cluster_config.cluster_config_c1.host
    token                  = data.ibm_container_cluster_config.cluster_config_c1.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config_c1.ca_certificate
  }
}

provider "helm" {
  alias = "helm_cluster_2"
  kubernetes {
    host                   = data.ibm_container_cluster_config.cluster_config_c2.host
    token                  = data.ibm_container_cluster_config.cluster_config_c2.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config_c2.ca_certificate
  }
}

provider "kubernetes" {
  alias                  = "kubernetes_cluster_1"
  host                   = data.ibm_container_cluster_config.cluster_config_c1.host
  token                  = data.ibm_container_cluster_config.cluster_config_c1.token
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config_c1.ca_certificate
}

provider "kubernetes" {
  alias                  = "kubernetes_cluster_2"
  host                   = data.ibm_container_cluster_config.cluster_config_c2.host
  token                  = data.ibm_container_cluster_config.cluster_config_c2.token
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config_c2.ca_certificate
}
