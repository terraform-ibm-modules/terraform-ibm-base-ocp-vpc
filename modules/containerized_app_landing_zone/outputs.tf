##############################################################################
# Cluster Outputs
##############################################################################

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "The name of the provisioned OpenShift cluster."
}

output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "The unique identifier assigned to the provisioned OpenShift cluster."
}

output "cluster_crn" {
  description = "The Cloud Resource Name (CRN) of the provisioned OpenShift cluster."
  value       = module.ocp_base.cluster_crn
}

output "workerpools" {
  description = "A list of worker pools associated with the provisioned cluster"
  value       = module.ocp_base.workerpools
}

output "ocp_version" {
  description = "The version of OpenShift running on the provisioned cluster."
  value       = module.ocp_base.ocp_version
}

##############################################################################
# VPC
##############################################################################

output "vpc_name" {
  description = "Name of the VPC created."
  value       = module.vpc.vpc_name
}

output "vpc_id" {
  description = "ID of the VPC created."
  value       = module.vpc.vpc_id
}

output "vpc_crn" {
  description = "CRN of the VPC created."
  value       = module.vpc.vpc_crn
}

##############################################################################
# Public Gateways
##############################################################################

output "public_gateways" {
  description = "Map of the public gateways by zone."
  value       = module.vpc.public_gateways
}

##############################################################################
# VPC flow logs
##############################################################################

output "vpc_flow_logs" {
  description = "Details of the VPC flow logs collector."
  value       = module.vpc.vpc_flow_logs
}

##############################################################################
# Network ACLs
##############################################################################

output "network_acls" {
  description = "List of shortnames and IDs of network ACLs."
  value       = module.vpc.network_acls
}

##############################################################################
# Subnet Outputs
##############################################################################

output "subnet_ids" {
  description = "The IDs of the subnets."
  value       = module.vpc.subnet_ids
}

output "private_path_subnet_id" {
  description = "The IDs of the subnets."
  value       = length(module.vpc.subnet_ids) > 0 ? module.vpc.subnet_ids[0] : null
}

output "subnet_detail_list" {
  description = "A list of subnets containing names, CIDR blocks, and zones."
  value       = module.vpc.subnet_detail_list
}

output "subnet_zone_list" {
  description = "A list of subnet IDs and subnet zones."
  value       = module.vpc.subnet_zone_list
}

output "subnet_detail_map" {
  description = "A map of subnets containing IDs, CIDR blocks, and zones."
  value       = module.vpc.subnet_detail_map
}

##############################################################################
# VPN Gateways Outputs
##############################################################################

output "vpn_gateways_name" {
  description = "List of names of VPN gateways."
  value       = module.vpc.vpn_gateways_name
}

output "vpn_gateways_data" {
  description = "Details of VPN gateways data."
  value       = module.vpc.vpn_gateways_data
}

##############################################################################
# VPE Outputs
##############################################################################

output "vpe_ips" {
  description = "The reserved IPs for endpoint gateways."
  value       = module.vpe_gateway.vpe_ips
}

output "vpe_crn" {
  description = "The CRN of the endpoint gateway."
  value       = module.vpe_gateway.crn
}

##############################################################################
# KMS Outputs
##############################################################################

output "kms_guid" {
  description = "KMS instance GUID"
  value       = local.cluster_existing_kms_guid
}

output "kms_account_id" {
  description = "The account ID of the KMS instance."
  value       = local.cluster_kms_account_id
}

output "kms_instance_crn" {
  value       = var.existing_kms_instance_crn == null ? var.kms_encryption_enabled_cluster ? module.kms[0].key_protect_crn : null : var.existing_kms_instance_crn
  description = "The CRN of the KMS instance"
}

##############################################################################
# Events Notification Outputs
##############################################################################

output "events_notification_crn" {
  description = "Event Notification crn"
  value       = local.eventnotification_crn
}

output "events_notification_guid" {
  description = "Event Notification guid"
  value       = local.eventnotification_guid
}


##############################################################################
# Secrets Manager Outputs
##############################################################################

output "secrets_manager_guid" {
  description = "GUID of Secrets Manager instance"
  value       = local.secrets_manager_guid
}

output "secrets_manager_crn" {
  value       = local.secrets_manager_crn
  description = "CRN of the Secrets Manager instance"
}

output "secrets_manager_region" {
  value       = local.secrets_manager_region
  description = "Region of the Secrets Manager instance"
}

##############################################################################
# COS Outputs
##############################################################################

output "cos_instance_crn" {
  description = "COS instance crn"
  value       = var.existing_cos_instance_crn != null ? var.existing_cos_instance_crn : module.cos[0].cos_instance_crn
}

output "cos_instance_guid" {
  description = "COS instance guid"
  value       = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].service_instance : module.cos[0].cos_instance_guid
}

output "cos_instance_id" {
  description = "COS instance ID"
  value       = var.existing_cos_instance_crn != null ? module.existing_cos_instance_crn_parser[0].resource : module.cos[0].cos_instance_crn
}


##############################################################################
# Cloud Monitoring Outputs
##############################################################################

output "cloud_monitoring_crn" {
  value       = local.cloud_monitoring_crn
  description = "The id of the provisioned IBM Cloud Monitoring instance."
}
output "cloud_monitoring_name" {
  value       = local.create_cloud_monitoring ? module.cloud_monitoring[0].name : null
  description = "The name of the provisioned IBM Cloud Monitoring instance."
}

output "cloud_monitoring_guid" {
  value       = local.create_cloud_monitoring ? module.cloud_monitoring[0].guid : module.existing_cloud_monitoring_crn_parser[0].service_instance
  description = "The guid of the provisioned IBM Cloud Monitoring instance."
}

output "cloud_monitoring_access_key_name" {
  value       = local.create_cloud_monitoring ? module.cloud_monitoring[0].access_key_name : null
  description = "The name of the IBM Cloud Monitoring access key for agents to use"
}

output "cloud_monitoring_access_key" {
  value       = local.create_cloud_monitoring ? module.cloud_monitoring[0].access_key : null
  description = "The IBM Cloud Monitoring access key for agents to use"
  sensitive   = true
}

##############################################################################
# Cloud Logs Outputs
##############################################################################

output "cloud_logs_crn" {
  value       = local.cloud_logs_crn
  description = "The id of the provisioned IBM Cloud Logs instance."
}

output "cloud_logs_guid" {
  value       = local.create_cloud_logs ? module.cloud_logs[0].guid : null
  description = "The guid of the provisioned IBM Cloud Logs instance."
}

output "cloud_logs_name" {
  value       = local.create_cloud_logs ? module.cloud_logs[0].name : null
  description = "The name of the provisioned IBM Cloud Logs instance."
}

output "cloud_logs_ingress_endpoint" {
  value       = local.create_cloud_logs ? module.cloud_logs[0].ingress_endpoint : null
  description = "The public ingress endpoint of the provisioned IBM Cloud Logs instance."
}

output "cloud_logs_ingress_private_endpoint" {
  value       = local.create_cloud_logs ? module.cloud_logs[0].ingress_private_endpoint : null
  description = "The private ingress endpoint of the provisioned IBM Cloud Logs instance."
}

output "cloud_logs_logs_policies_details" {
  value       = local.create_cloud_logs ? module.cloud_logs[0].logs_policies_details : null
  description = "The details of the IBM Cloud logs policies created."
}

output "logs_bucket_crn" {
  description = "Logs Cloud Object Storage bucket CRN"
  value       = module.cloud_logs_buckets.buckets[local.data_bucket_name].bucket_crn
}

output "metrics_bucket_crn" {
  description = "Metrics Cloud Object Storage bucket CRN"
  value       = module.cloud_logs_buckets.buckets[local.metrics_bucket_name].bucket_crn
}

##############################################################################
# Activity Tracker Event Routing Outputs
##############################################################################

output "activity_tracker_cos_target_bucket_name" {
  value       = var.existing_activity_tracker_cos_target_bucket_name == null ? var.enable_activity_tracker_event_routing_to_cos_bucket ? module.at_cos_bucket[0].buckets[local.activity_tracker_cos_target_bucket_name].bucket_name : null : var.existing_activity_tracker_cos_target_bucket_name
  description = "he name of the object storage bucket which is set as activity tracker event routing target to collect audit events."
}

output "activity_tracker_targets" {
  value       = module.activity_tracker.activity_tracker_targets
  description = "The map of created Activity Tracker Event Routing targets"
}

output "activity_tracker_routes" {
  value       = module.activity_tracker.activity_tracker_routes
  description = "The map of created Activity Tracker Event Routing routes"
}

##############################################################################
# SCC-WP Outputs
##############################################################################

output "scc_workload_protection_id" {
  description = "SCC Workload Protection instance ID"
  value       = module.scc_wp.id
}

output "scc_workload_protection_crn" {
  description = "SCC Workload Protection instance CRN"
  value       = module.scc_wp.crn
}

output "scc_workload_protection_name" {
  description = "SCC Workload Protection instance name"
  value       = module.scc_wp.name
}

output "scc_workload_protection_ingestion_endpoint" {
  description = "SCC Workload Protection instance ingestion endpoint"
  value       = module.scc_wp.name
}

output "scc_workload_protection_api_endpoint" {
  description = "SCC Workload Protection API endpoint"
  value       = module.scc_wp.api_endpoint
  sensitive   = true
}
