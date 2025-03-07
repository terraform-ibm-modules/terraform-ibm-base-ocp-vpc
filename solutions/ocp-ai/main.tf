# Retrieve existing OpenShift cluster details
data "ibm_container_vpc_cluster" "cluster" {
  name = var.cluster_name
}
# Retrieve existing worker node details
data "ibm_container_vpc_worker_pool" "pool" {
  cluster          = var.cluster_name
  worker_pool_name = var.pool_name
}
# Retrieve existing  OpenShift cluster version details
data "ibm_container_cluster_versions" "cluster_versions" {
  resource_group_id = data.ibm_container_vpc_cluster.cluster.resource_group_id
}
# Retrieve existing  existing details
data "ibm_container_addons" "addons" {
  cluster = var.cluster_name
}
########################################################################################################################
# VALIDATIONS
########################################################################################################################

locals {
  os_rhel          = "REDHAT_8_64"
  os_rhcos         = "RHCOS"
  os_rhel9         = "RHEL_9_64"
  default_pool     = data.ibm_container_vpc_worker_pool.pool
  ocp_version      = data.ibm_container_cluster_versions.cluster_versions.default_openshift_version
  allowed_versions = ["4.16", "4.17", "4.18"]

  # Validation 1: To check the OCP Cluster version: OCP AI Addon Supports OpenShift cluster versions: >=4.16.0 <4.18.0
  # tflint-ignore: terraform_unused_declarations
  validation_ocp_version = contains(local.allowed_versions, join(".", slice(split(".", local.ocp_version), 0, 2))) ? true : tobool("OCPAI Addon Supports OpenShift cluster versions: >=4.16.0 <4.18.0")

  # Validation 2: The Cluster must have at least two worker nodes.
  # tflint-ignore: terraform_unused_declarations
  validate_worker_count = local.default_pool.worker_count == 2 ? true : tobool("The Cluster must have at least two worker nodes.")

  # Validation 3: All Worker nodes in the cluster must have minimum configuration as 8-core, 32GB memory.
  # tflint-ignore: terraform_unused_declarations
  validation_flavour = local.default_pool.flavor == "bx2.8x32" ? true : tobool("All Worker nodes in the cluster must have minimum configuration as 8-core, 32GB memory.")

  # Validation 4: Cluster must have access to the public internet.

  # Validation 5: Check if already ocp-ai addon is installed in the cluster.
  # tflint-ignore: terraform_unused_declarations
  validate_openshift_ai = contains([for addon in data.ibm_container_addons.addons.addons : addon.name], "openshift-ai") ? tobool("Openshift-ai already installled in this cluster") : true

  # validate operating system
  # tflint-ignore: terraform_unused_declarations
  validate_operating_system = contains([local.os_rhel9, local.os_rhel, local.os_rhcos], local.default_pool.operating_system) ? true : tobool("RHEL 9 (RHEL_9_64), RHEL 8 (REDHAT_8_64) or Red Hat Enterprise Linux CoreOS (RHCOS) are the allowed OS values.")

  # Validation 6: Check the outbound traffic protection should be disabled, if any of the OpenShift Pipelines, Node Feature Discovery, or NVIDIA GPU operators are used with OCP AI addon.
  #validate_outbound_traffic_protection = data.ibm_container_vpc_cluster.cluster.disable_outbound_traffic_protection == true ?  true : tobool("outbound traffic protection should be disabled, if any of the OpenShift Pipelines, Node Feature Discovery, or NVIDIA GPU operators are used with OCP AI addon.")

  # Validation 7: GPU Worker node validation. If adding a GPU worker node, validation should be added for minimal configuration as validation3 and machine type for GPU Nodes.
  # tflint-ignore: terraform_unused_declarations
  validate_gpu_node = var.pool_name == "gpu" ? local.default_pool.flavor == "bx2.8x32" ? true : tobool("All Worker nodes in the cluster must have minimum configuration as 8-core, 32GB memory.") : true
}

#####################################################################################################################
#Create Openshift_ai addon
#####################################################################################################################
resource "ibm_container_addons" "addons" {
  cluster           = data.ibm_container_vpc_cluster.cluster.name
  manage_all_addons = false
  addons {
    name    = "openshift-ai"
    version = "416"
  }
}
