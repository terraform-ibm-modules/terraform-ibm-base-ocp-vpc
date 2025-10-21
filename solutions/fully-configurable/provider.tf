provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  visibility       = var.provider_visibility
}

provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.cluster_config.host
  token                  = data.ibm_container_cluster_config.cluster_config.token
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
}

provider "helm" {
  kubernetes = {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
  }
  # No registry authentication required - using public registries
}

# Retrieve information about an existing VPC cluster
data "ibm_container_vpc_cluster" "cluster" {
  count             = local.is_vpc_cluster ? 1 : 0
  name              = var.cluster_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}

# Retrieve information about an existing Classic cluster
data "ibm_container_cluster" "cluster" {
  count             = local.is_vpc_cluster ? 0 : 1
  name              = var.cluster_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}
