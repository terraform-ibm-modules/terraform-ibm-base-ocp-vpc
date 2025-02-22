########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}

# FOR DEBUGGING # TODO: Remove below outputs after testing
output "cluster_vpc_subnets" {
  description = "cluster_vpc_subnets"
  value       = local.cluster_vpc_subnets
}

output "data_vpc_subnets" {
  description = "data_vpc_subnets"
  value       = data.ibm_is_subnets.vpc_subnets.subnets
}

output "vpc_id" {
  description = "vpc_id"
  value       = var.vpc_id
}
