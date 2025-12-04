provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

data "ibm_iam_auth_token" "auth_token" {}

provider "restapi" {
  uri = "https://resource-controller.cloud.ibm.com"
  headers = {
    Authorization = data.ibm_iam_auth_token.auth_token.iam_access_token
  }
  write_returns_object = true
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
