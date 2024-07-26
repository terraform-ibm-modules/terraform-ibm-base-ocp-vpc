########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}

output "test_vpes" {
  description = "To remove"
  value = {
    "master_vpe" : module.ocp_base.master_vpe
    "api_vpe" : module.ocp_base.api_vpe
    "registry_vpe" : module.ocp_base.registry_vpe
  }
}
