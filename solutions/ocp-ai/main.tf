# Retrieve existing OpenShift cluster details
data "ibm_container_vpc_cluster" "cluster" {
   
  id   = var.cluster_id
}

# Fetch the worker pool details using the cluster ID
data "ibm_container_worker_pool" "pool" {
   worker_pool_name = data.ibm_container_vpc_cluster.cluster.worker_pools[0].name 
  cluster = data.ibm_container_vpc_cluster.cluster.id
}
resource "ibm_container_addons" "addons" {
  depends_on = [ data.ibm_container_vpc_cluster.cluster ]
  cluster = data.ibm_container_vpc_cluster.cluster.id
  addons {
    name    = "openshift-ai"
    version = "416"
  }
}