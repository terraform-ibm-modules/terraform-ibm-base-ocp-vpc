##############################################################################
# OCP Cluster Version
##############################################################################

data "external" "get_ocp_cluster_version" {
  program = ["bash", "${path.module}/scripts/get_ocp_cluster_version.sh"]

  query = {
    cluster_name     = var.cluster_name
    ibmcloud_api_key = var.ibmcloud_api_key
  }
}
