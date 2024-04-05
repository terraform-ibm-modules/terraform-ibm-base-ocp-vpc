########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}

output "test_vpe_fqdns" {
  value       = module.ocp_base.vpe_fqdns
  description = "for testing purposes"
}

output "test_vpe_ips" {
  value       = module.ocp_base.vpe_ips
  description = "for testing purposes"
}
