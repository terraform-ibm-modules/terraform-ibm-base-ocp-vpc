########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned OpenShift cluster."
}

output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "The unique identifier assigned to the provisioned OpenShift cluster."
}

output "cluster_crn" {
  description = "The Cloud Resource Name (CRN) of the provisioned OpenShift cluster."
  value       = module.ocp_base.cluster_crn
}

output "vpc_id" {
  description = "The ID of the Virtual Private Cloud (VPC) in which the cluster is deployed."
  value       = module.ocp_base.vpc_id
}

output "region" {
  description = "The IBM Cloud region where the cluster is deployed."
  value       = module.ocp_base.region
}
