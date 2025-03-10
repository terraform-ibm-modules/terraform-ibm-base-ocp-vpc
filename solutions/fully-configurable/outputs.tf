########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}

output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "The id of the provisioned cluster."
}
