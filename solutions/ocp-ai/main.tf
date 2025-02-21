# Retrieve existing OpenShift cluster details
data "ibm_container_vpc_cluster" "cluster" {
   name = var.cluster_name
}

resource "ibm_container_addons" "addons" {
  depends_on = [ data.ibm_container_vpc_cluster.cluster ]
  cluster = data.ibm_container_vpc_cluster.cluster.name
  addons {
    name    = "openshift-ai"
    version = "416"
  }
}
