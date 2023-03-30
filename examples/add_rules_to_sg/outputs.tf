##############################################################################
# Outputs
##############################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}


output "kube_vpc_rule_id" {
  description = "The kube-vpc-id security group rule ids"
  value       = join(",", [for rule in data.ibm_is_security_group.kube_vpc_sg.rules : rule.rule_id])
}


output "kube_cluster_rule_id" {
  description = "The kube-cluster-id security group rule ids"
  value       = join(",", [for rule in data.ibm_is_security_group.kube_cluster_sg.rules : rule.rule_id])
}

##############################################################################
