########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}

output "data_block_ocp_version" {
  value = module.ocp_base.data_source_external_ocp_version
}
