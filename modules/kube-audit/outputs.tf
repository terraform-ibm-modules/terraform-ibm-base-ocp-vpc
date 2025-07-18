########################################################################################################################
# Outputs
########################################################################################################################

output "audit_namespace" {
  description = "The namespace where the audit webhook is deployed."
  value       = var.audit_namespace
}

output "audit_deployment_name" {
  description = "The name of the audit webhook listener deployment."
  value       = var.audit_deployment_name
}

output "webhook_listener_image" {
  description = "The image used for the audit webhook listener."
  value       = var.audit_webhook_listener_image
}

output "webhook_listener_image_version" {
  description = "The version of the audit webhook listener image."
  value       = var.audit_webhook_listener_image_version
}

output "audit_log_policy" {
  description = "The audit log policy configuration applied to the webhook listener."
  value       = var.audit_log_policy
}
