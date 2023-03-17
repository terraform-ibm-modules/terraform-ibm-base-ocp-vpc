##############################################################################
# Outputs
##############################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}

output "rules_kube_vpc" {
  description = "The kube-vpc-id security group id and rules"
  value       = "${ibm_is_security_group.kube_vpc_sg.id} => ${ibm_is_security_group.kube_vpc_sg.rules}"
}

output "rules_kube_cluster" {
  description = "The kube-cluster-id security group id and rules"
  value       = "${ibm_is_security_group.kube_cluster_sg.id} => ${ibm_is_security_group.kube_cluster_sg.rules}"
}

##############################################################################
