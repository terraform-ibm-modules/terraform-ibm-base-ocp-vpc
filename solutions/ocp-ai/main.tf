# Retrieve existing OpenShift cluster details
data "ibm_container_vpc_cluster" "cluster" {
  name = var.cluster_name
}

########################################################################################################################
# VALIDATIONS
########################################################################################################################

# Validation 1: To check the OCP Cluster version: OCP AI Addon Supports OpenShift cluster versions: >=4.16.0 <4.18.0
# Validation 2: The Cluster must have at least two worker nodes.
# Validation 3: All Worker nodes in the cluster must have minimum configuration as 8-core, 32GB memory.
# Validation 4: Cluster must have access to the public internet.
# Validation 5: Check if already ocp-ai addon is installed in the cluster.
# Validation 6: Check the outbound traffic protection should be disabled, if any of the OpenShift Pipelines, Node Feature Discovery, or NVIDIA GPU operators are used with OCP AI addon.
# Validation 7: GPU Worker node validation. If adding a GPU worker node, validation should be added for minimal configuration as validation3 and machine type for GPU Nodes.

resource "ibm_container_addons" "addons" {
  cluster           = data.ibm_container_vpc_cluster.cluster.name
  manage_all_addons = false
  addons {
    name    = "openshift-ai"
    version = "416"
  }
}
