##############################################################################
# Outputs
##############################################################################

output "cluster_id" {
  description = "ID of cluster created"
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].id : ibm_container_vpc_cluster.cluster[0].id
  depends_on  = [null_resource.confirm_network_healthy]
}

output "cluster_name" {
  description = "Name of the created cluster"
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].name : ibm_container_vpc_cluster.cluster[0].name
  depends_on  = [null_resource.confirm_network_healthy]
}

output "cluster_crn" {
  description = "CRN for the created cluster"
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].crn : ibm_container_vpc_cluster.cluster[0].crn
  depends_on  = [null_resource.confirm_network_healthy]
}

output "workerpools" {
  description = "Worker pools created"
  value       = data.ibm_container_vpc_worker_pool.all_pools
}

output "ocp_version" {
  description = "Openshift Version of the cluster"
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].kube_version : ibm_container_vpc_cluster.cluster[0].kube_version
}

output "cos_crn" {
  description = "CRN of the COS instance"
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].cos_instance_crn : ibm_container_vpc_cluster.cluster[0].cos_instance_crn
}

output "vpc_id" {
  description = "ID of the clusters VPC"
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].vpc_id : ibm_container_vpc_cluster.cluster[0].vpc_id
}

output "region" {
  description = "Region cluster is deployed in"
  value       = var.region
}

output "resource_group_id" {
  description = "Resource group ID the cluster is deployed in"
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].resource_group_id : ibm_container_vpc_cluster.cluster[0].resource_group_id
}

output "ingress_hostname" {
  description = "The hostname that was assigned to your Ingress subdomain."
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].ingress_hostname : ibm_container_vpc_cluster.cluster[0].ingress_hostname
}

output "private_service_endpoint_url" {
  description = "Private service endpoint URL"
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].private_service_endpoint_url : ibm_container_vpc_cluster.cluster[0].private_service_endpoint_url
}

output "public_service_endpoint_url" {
  description = "Public service endpoint URL"
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].public_service_endpoint_url : ibm_container_vpc_cluster.cluster[0].public_service_endpoint_url
}

output "master_url" {
  description = "The URL of the Kubernetes master."
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].master_url : ibm_container_vpc_cluster.cluster[0].master_url
}

output "vpe_url" {
  description = "The virtual private endpoint URL of the Kubernetes cluster."
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].vpe_service_endpoint_url : ibm_container_vpc_cluster.cluster[0].vpe_service_endpoint_url
}

output "kms_config" {
  description = "KMS configuration details"
  value       = var.kms_config
}

output "operating_system" {
  description = "The operating system of the workers in the default worker pool."
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].operating_system : ibm_container_vpc_cluster.cluster[0].operating_system
}

output "master_status" {
  description = "The status of the Kubernetes master."
  value       = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].master_status : ibm_container_vpc_cluster.cluster[0].master_status
}

output "master_vpe" {
  description = "Info about the master, or default, VPE. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway"
  # value       = one([for vpe in data.ibm_is_virtual_endpoint_gateways.all_vpes.virtual_endpoint_gateways : vpe if strcontains(vpe.name, "iks-${local.cluster_id}")])
  value = local.master_vpe_id
}

output "api_vpe" {
  description = "Info about the api VPE, if it exists. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway"
  # value       = one([for vpe in data.ibm_is_virtual_endpoint_gateways.all_vpes.virtual_endpoint_gateways : vpe if strcontains(vpe.name, "iks-api-${var.vpc_id}")])
  value = local.api_vpe_id
}

output "registry_vpe" {
  description = "Info about the registry VPE, if it exists. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway"
  # value       = one([for vpe in data.ibm_is_virtual_endpoint_gateways.all_vpes.virtual_endpoint_gateways : vpe if strcontains(vpe.name, "iks-registry-${var.vpc_id}")])
  value = local.registry_vpe_id
}
