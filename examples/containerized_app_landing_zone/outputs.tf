##############################################################################
# Cluster Outputs
##############################################################################

output "cluster_name" {
  value       = module.openshift_landing_zone.cluster_name
  description = "The name of the provisioned OpenShift cluster."
}

output "cluster_id" {
  value       = module.openshift_landing_zone.cluster_id
  description = "The unique identifier assigned to the provisioned OpenShift cluster."
}

output "cluster_crn" {
  description = "The Cloud Resource Name (CRN) of the provisioned OpenShift cluster."
  value       = module.openshift_landing_zone.cluster_crn
}

output "workerpools" {
  description = "A list of worker pools associated with the provisioned cluster"
  value       = module.openshift_landing_zone.workerpools
}

output "ocp_version" {
  description = "The version of OpenShift running on the provisioned cluster."
  value       = module.openshift_landing_zone.ocp_version
}


##############################################################################
# VPC
##############################################################################

output "vpc_name" {
  description = "Name of the VPC created."
  value       = module.openshift_landing_zone.vpc_name
}

output "vpc_id" {
  description = "ID of the VPC created."
  value       = module.openshift_landing_zone.vpc_id
}

output "vpc_crn" {
  description = "CRN of the VPC created."
  value       = module.openshift_landing_zone.vpc_crn
}

##############################################################################
# Public Gateways
##############################################################################

output "public_gateways" {
  description = "Map of the public gateways by zone."
  value       = module.openshift_landing_zone.public_gateways
}

##############################################################################
# VPC flow logs
##############################################################################

output "vpc_flow_logs" {
  description = "Details of the VPC flow logs collector."
  value       = module.openshift_landing_zone.vpc_flow_logs
}

##############################################################################
# Network ACLs
##############################################################################

output "network_acls" {
  description = "List of shortnames and IDs of network ACLs."
  value       = module.openshift_landing_zone.network_acls
}

##############################################################################
# Subnet Outputs
##############################################################################

output "subnet_ids" {
  description = "The IDs of the subnets."
  value       = module.openshift_landing_zone.subnet_ids
}

output "private_path_subnet_id" {
  description = "The IDs of the subnets."
  value       = length(module.openshift_landing_zone.subnet_ids) > 0 ? module.openshift_landing_zone.subnet_ids[0] : null
}

output "subnet_detail_list" {
  description = "A list of subnets containing names, CIDR blocks, and zones."
  value       = module.openshift_landing_zone.subnet_detail_list
}

output "subnet_zone_list" {
  description = "A list of subnet IDs and subnet zones."
  value       = module.openshift_landing_zone.subnet_zone_list
}

output "subnet_detail_map" {
  description = "A map of subnets containing IDs, CIDR blocks, and zones."
  value       = module.openshift_landing_zone.subnet_detail_map
}

##############################################################################
# VPN Gateways Outputs
##############################################################################

output "vpn_gateways_name" {
  description = "List of names of VPN gateways."
  value       = module.openshift_landing_zone.vpn_gateways_name
}

output "vpn_gateways_data" {
  description = "Details of VPN gateways data."
  value       = module.openshift_landing_zone.vpn_gateways_data
}

##############################################################################
# VPE Outputs
##############################################################################

output "vpe_ips" {
  description = "The reserved IPs for endpoint gateways."
  value       = module.openshift_landing_zone.vpe_ips
}

output "vpe_crn" {
  description = "The CRN of the endpoint gateway."
  value       = module.openshift_landing_zone.vpe_crn
}

##############################################################################
# KMS Outputs
##############################################################################

output "kms_guid" {
  description = "KMS instance GUID"
  value       = module.openshift_landing_zone.kms_guid
}

output "kms_account_id" {
  description = "The account ID of the KMS instance."
  value       = module.openshift_landing_zone.kms_account_id
}

output "kms_instance_crn" {
  value       = module.openshift_landing_zone.kms_instance_crn
  description = "The CRN of the KMS instance"
}

##############################################################################
# Events Notification Outputs
##############################################################################

output "events_notification_crn" {
  description = "Event Notification crn"
  value       = module.openshift_landing_zone.events_notification_crn
}

output "events_notification_guid" {
  description = "Event Notification guid"
  value       = module.openshift_landing_zone.events_notification_guid
}

##############################################################################
# Secrets Manager Outputs
##############################################################################

output "secrets_manager_guid" {
  description = "GUID of Secrets Manager instance"
  value       = module.openshift_landing_zone.secrets_manager_guid
}

output "secrets_manager_crn" {
  value       = module.openshift_landing_zone.secrets_manager_crn
  description = "CRN of the Secrets Manager instance"
}

output "secrets_manager_region" {
  value       = module.openshift_landing_zone.secrets_manager_region
  description = "Region of the Secrets Manager instance"
}

##############################################################################
# COS Outputs
##############################################################################

output "cos_instance_crn" {
  description = "COS instance crn"
  value       = module.openshift_landing_zone.cos_instance_crn
}

output "cos_instance_guid" {
  description = "COS instance guid"
  value       = module.openshift_landing_zone.cos_instance_guid
}

##############################################################################
# Cloud Monitoring Outputs
##############################################################################

output "cloud_monitoring_crn" {
  value       = module.openshift_landing_zone.cloud_monitoring_crn
  description = "The id of the provisioned IBM Cloud Monitoring instance."
}
output "cloud_monitoring_name" {
  value       = module.openshift_landing_zone.cloud_monitoring_name
  description = "The name of the provisioned IBM Cloud Monitoring instance."
}

output "cloud_monitoring_guid" {
  value       = module.openshift_landing_zone.cloud_monitoring_guid
  description = "The guid of the provisioned IBM Cloud Monitoring instance."
}

output "cloud_monitoring_access_key_name" {
  value       = module.openshift_landing_zone.cloud_monitoring_access_key_name
  description = "The name of the IBM Cloud Monitoring access key for agents to use"
}

output "cloud_monitoring_access_key" {
  value       = module.openshift_landing_zone.cloud_monitoring_access_key
  description = "The IBM Cloud Monitoring access key for agents to use"
  sensitive   = true
}

##############################################################################
# Cloud Logs Outputs
##############################################################################

output "cloud_logs_crn" {
  value       = module.openshift_landing_zone.cloud_logs_crn
  description = "The id of the provisioned IBM Cloud Logs instance."
}

output "cloud_logs_guid" {
  value       = module.openshift_landing_zone.cloud_logs_guid
  description = "The guid of the provisioned IBM Cloud Logs instance."
}

output "cloud_logs_name" {
  value       = module.openshift_landing_zone.cloud_logs_name
  description = "The name of the provisioned IBM Cloud Logs instance."
}

output "logs_bucket_crn" {
  description = "Logs Cloud Object Storage bucket CRN"
  value       = module.openshift_landing_zone.logs_bucket_crn
}

output "metrics_bucket_crn" {
  description = "Metrics Cloud Object Storage bucket CRN"
  value       = module.openshift_landing_zone.metrics_bucket_crn
}

##############################################################################
# Activity Tracker Event Routing Outputs
##############################################################################

output "activity_tracker_cos_target_bucket_name" {
  value       = module.openshift_landing_zone.activity_tracker_cos_target_bucket_name
  description = "he name of the object storage bucket which is set as activity tracker event routing target to collect audit events."
}

output "activity_tracker_targets" {
  value       = module.openshift_landing_zone.activity_tracker_targets
  description = "The map of created Activity Tracker Event Routing targets"
}

output "activity_tracker_routes" {
  value       = module.openshift_landing_zone.activity_tracker_routes
  description = "The map of created Activity Tracker Event Routing routes"
}

##############################################################################
# SCC-WP Outputs
##############################################################################

output "scc_workload_protection_id" {
  description = "SCC Workload Protection instance ID"
  value       = module.openshift_landing_zone.scc_workload_protection_id
}

output "scc_workload_protection_crn" {
  description = "SCC Workload Protection instance CRN"
  value       = module.openshift_landing_zone.scc_workload_protection_crn
}

output "scc_workload_protection_name" {
  description = "SCC Workload Protection instance name"
  value       = module.openshift_landing_zone.scc_workload_protection_name
}
