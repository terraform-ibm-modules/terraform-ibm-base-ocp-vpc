########################################################################################################################
# Outputs
########################################################################################################################

output "resource_group_id" {
  description = "The id of the resource group where resources are created"
  value       = module.resource_group.resource_group_id
}

output "resource_group_name" {
  description = "The name of the resource group where resources are created"
  value       = module.resource_group.resource_group_name
}

output "event_notifications_instance_crn" {
  value       = module.event_notifications.crn
  description = "CRN of created event notification"
}
