##############################################################################
# Outputs
##############################################################################

output "cluster_id" {
  description = "ID of the cluster"
  value       = module.cluster.cluster_id
}

output "cluster_name" {
  description = "Name of the cluster"
  value       = module.cluster.cluster_name
}

output "cluster_crn" {
  description = "CRN of the cluster"
  value       = module.cluster.cluster_crn
}

output "workerpools" {
  description = "Worker pools created"
  value       = module.cluster.workerpools
}

output "ocp_version" {
  description = "Openshift Version of the cluster"
  value       = module.cluster.cluster_version
}

output "cos_crn" {
  description = "CRN of the COS instance"
  value       = module.cluster.cos_crn
}

output "vpc_id" {
  description = "ID of the clusters VPC"
  value       = module.cluster.vpc_id
}

output "region" {
  description = "Region that the cluster is deployed to"
  value       = var.region
}

output "resource_group_id" {
  description = "Resource group ID the cluster is deployed in"
  value       = module.cluster.resource_group_id
}

output "ingress_hostname" {
  description = "The hostname that was assigned to your Ingress subdomain."
  value       = module.cluster.ingress_hostname
}

output "private_service_endpoint_url" {
  description = "Private service endpoint URL"
  value       = module.cluster.private_service_endpoint_url
}

output "public_service_endpoint_url" {
  description = "Public service endpoint URL"
  value       = module.cluster.public_service_endpoint_url
}

output "master_url" {
  description = "The URL of the Kubernetes master."
  value       = module.cluster.master_url
}

output "vpe_url" {
  description = "The virtual private endpoint URL of the Kubernetes cluster."
  value       = module.cluster.vpe_url
}

output "kms_config" {
  description = "KMS configuration details"
  value       = var.kms_config
}

output "operating_system" {
  description = "The operating system of the workers in the default worker pool."
  value       = module.cluster.operating_system
}

output "master_status" {
  description = "The status of the Kubernetes master."
  value       = module.cluster.master_status
}

output "master_vpe" {
  description = "Info about the master, or default, VPE. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway"
  value       = module.cluster.master_vpe
}

output "api_vpe" {
  description = "Info about the api VPE, if it exists. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway"
  value       = module.cluster.api_vpe
}

output "registry_vpe" {
  description = "Info about the registry VPE, if it exists. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway"
  value       = module.cluster.registry_vpe
}

output "secrets_manager_integration_config" {
  description = "Information about the Secrets Manager instance that is used to store the Ingress certificates."
  value       = module.cluster.secrets_manager_integration_config
}
