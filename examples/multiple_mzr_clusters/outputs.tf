##############################################################################
# Outputs
##############################################################################

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Vpc id"
}

output "cluster_name_1" {
  value       = module.ocp_base_cluster_1.cluster_name
  description = "Name of the created cluster 1"
}

output "cluster_name_2" {
  value       = module.ocp_base_cluster_2.cluster_name
  description = "Name of the created cluster 2"
}

##############################################################################
