##############################################################################
# Outputs
##############################################################################

output "cluster_id" {
  description = "ID of cluster created"
  value       = module.fscloud.cluster_id
}

output "cluster_name" {
  description = "Name of the created cluster"
  value       = module.fscloud.cluster_name
}

output "cluster_crn" {
  description = "CRN for the created cluster"
  value       = module.fscloud.cluster_crn
}

output "workerpools" {
  description = "Worker pools created"
  value       = module.fscloud.workerpools
}

output "ocp_version" {
  description = "Openshift Version of the cluster"
  value       = module.fscloud.ocp_version
}

output "cos_crn" {
  description = "CRN of the COS instance"
  value       = module.fscloud.cos_crn
}

output "vpc_id" {
  description = "ID of the clusters VPC"
  value       = module.fscloud.vpc_id
}

output "region" {
  description = "Region cluster is deployed in"
  value       = var.region
}

output "resource_group_id" {
  description = "Resource group ID the cluster is deployed in"
  value       = module.fscloud.resource_group_id
}

output "ingress_hostname" {
  description = "Ingress hostname"
  value       = module.fscloud.ingress_hostname
}

output "private_service_endpoint_url" {
  description = "Private service endpoint URL"
  value       = module.fscloud.private_service_endpoint_url
}
