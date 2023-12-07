########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned cluster."
}

output "kms_cross_account_id" {
  value       = var.kms_cross_account_id
  description = "Id of the cross account which owns the KMS instance."
}

output "kms_instance_guid" {
  value       = var.kms_instance_guid
  description = "GUID of the KMS instance existing in the cross account."
}
