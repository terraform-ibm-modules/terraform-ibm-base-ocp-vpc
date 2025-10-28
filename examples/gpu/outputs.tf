########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}

output "workerpools" {
  value       = module.ocp_base.workerpools
  description = "Worker pools created in the cluster."
}
