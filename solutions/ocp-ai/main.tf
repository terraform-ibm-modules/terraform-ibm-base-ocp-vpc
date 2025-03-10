# Retrieve existing OpenShift cluster details
data "ibm_container_vpc_cluster" "cluster" {
  name = var.cluster_name
}
# # Retrieve existing  OpenShift cluster version details
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

  worker_pool = { for idx, pool in data.ibm_container_vpc_cluster.cluster.worker_pools : idx => pool if pool.name == var.pool_name }
  ocp_version = data.ibm_container_cluster_versions.cluster_versions.default_openshift_version
  kubeconfig  = "../../kubeconfig"
}
#tflint-ignore: terraform_unused_declarations
resource "null_resource" "validations" {
  provisioner "local-exec" {
    #command = "scripts/validations.sh ${local.ocp_version} ${local.worker_pool[0].worker_count} ${local.worker_pool[0].flavor} '${join(" ", [for addon in data.ibm_container_addons.addons.addons : addon.name])}' ${local.worker_pool[0].operating_system} ${var.pool_name}"
    command     = "scripts/validations.sh \"${local.ocp_version}\" ${local.worker_pool[0].worker_count} \"${local.worker_pool[0].flavor}\" \"${join(" ", [for addon in data.ibm_container_addons.addons.addons : addon.name])}\" \"${local.worker_pool[0].operating_system}\" \"${var.pool_name}\""
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = local.kubeconfig
    }
  }
}


###################################################################################################################
#Create OpenShift AI addon
###################################################################################################################
resource "ibm_container_addons" "addons" {
  depends_on = [null_resource.validations]

  cluster           = data.ibm_container_vpc_cluster.cluster.name
  manage_all_addons = false

  addons {
    name    = "openshift-ai"
    version = "416"
  }
}
