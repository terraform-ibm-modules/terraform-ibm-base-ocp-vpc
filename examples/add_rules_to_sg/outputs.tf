##############################################################################
# Outputs
##############################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}

output "vpc_security_group" {
  value       = data.ibm_security_group.get_vpc_sg
  description = "Get VPC SG rules"
}

output "vpc_cluster_security_group" {
  value       = data.ibm_security_group.get_vpc_cluster_sg
  description = "Get VPC Cluster SG rules"
}

output "allow_ssh_rule" {
  value       = data.ibm_security_group.allow_ssh
  description = "Allow SSH rule"
}

# output "vpc_cluster_security_group" {
#   value = data.ibm_security_group.get_vpc_cluster_sg
# }

##############################################################################
