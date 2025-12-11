########################################################################################################################
# Resource group
########################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.0"
  existing_resource_group_name = var.existing_resource_group_name
}

########################################################################################################################
# Add-ons
########################################################################################################################

module "ocp_cluster_with_add_ons" {
  source                                    = "../../modules/containerized_app_landing_zone"
  prefix                                    = var.prefix
  region                                    = var.region
  ibmcloud_api_key                          = var.ibmcloud_api_key
  provider_visibility                       = var.provider_visibility
  resource_group_id                         = module.resource_group.resource_group_id
  kms_encryption_enabled_cluster            = true
  existing_kms_instance_crn                 = var.existing_kms_instance_crn
  existing_cluster_kms_key_crn              = var.existing_cluster_kms_key_crn
  kms_endpoint_type                         = "private"
  key_protect_allowed_network               = "private-only"
  kms_encryption_enabled_boot_volume        = true
  existing_boot_volume_kms_key_crn          = var.existing_boot_volume_kms_key_crn
  kms_plan                                  = "tiered-pricing"
  en_service_plan                           = "standard"
  en_service_endpoints                      = "public-and-private"
  existing_secrets_manager_crn              = var.existing_secrets_manager_crn
  secrets_manager_service_plan              = "standard"
  secrets_manager_endpoint_type             = "private"
  existing_event_notifications_instance_crn = var.existing_event_notifications_instance_crn
  existing_cos_instance_crn                 = var.existing_cos_instance_crn
  cos_instance_plan                         = "standard"
  management_endpoint_type_for_buckets      = "direct"
  existing_cloud_monitoring_crn             = var.existing_cloud_monitoring_crn
  cloud_monitoring_plan                     = "graduated-tier"
  existing_cloud_logs_crn                   = var.existing_cloud_logs_crn
  scc_workload_protection_service_plan      = "graduated-tier"
  enable_vpc_flow_logs                      = true
  app_config_plan                           = "enterprise"
  app_config_service_endpoints              = "public-and-private"
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_cluster_with_add_ons.cluster_id
  resource_group_id = module.resource_group.resource_group_id
  config_dir        = "${path.module}/../../kubeconfig"
}

##############################################################################
# Monitoring Agents
##############################################################################

module "monitoring_agent" {
  source                    = "terraform-ibm-modules/monitoring-agent/ibm"
  version                   = "1.19.0"
  cluster_id                = module.ocp_cluster_with_add_ons.cluster_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  is_vpc_cluster            = true
  access_key                = module.ocp_cluster_with_add_ons.cloud_monitoring_access_key
  instance_region           = var.region
  metrics_filter            = [{ exclude = "metricA.*" }, { include = "metricB.*" }]
  container_filter          = [{ type = "exclude", parameter = "kubernetes.namespace.name", name = "kube-system" }]
  blacklisted_ports         = [22, 2379, 3306]
  agent_tags                = { "environment" : "test", "custom" : "value" }
  agent_mode                = "troubleshooting"
}

##############################################################################
# Logs Agent
##############################################################################

locals {
  logs_agent_namespace = "ibm-observe"
  logs_agent_name      = "logs-agent"
}

module "trusted_profile" {
  source                      = "terraform-ibm-modules/trusted-profile/ibm"
  version                     = "3.2.0"
  trusted_profile_name        = "${var.prefix}-profile"
  trusted_profile_description = "Logs agent Trusted Profile"
  # As a `Sender`, you can send logs to your IBM Cloud Logs service instance - but not query or tail logs. This role is meant to be used by agent and routers sending logs.
  trusted_profile_policies = [{
    roles             = ["Sender"]
    unique_identifier = "logs-agent"
    resources = [{
      service = "logs"
    }]
  }]
  # Set up fine-grained authorization for `logs-agent` running in ROKS cluster in `ibm-observe` namespace.
  trusted_profile_links = [{
    cr_type           = "ROKS_SA"
    unique_identifier = "logs-agent-link"
    links = [{
      crn       = module.ocp_cluster_with_add_ons.cluster_crn
      namespace = local.logs_agent_namespace
      name      = local.logs_agent_name
    }]
    }
  ]
}

module "logs_agent" {
  source                    = "terraform-ibm-modules/logs-agent/ibm"
  version                   = "1.10.0"
  cluster_id                = module.ocp_cluster_with_add_ons.cluster_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  # Logs agent
  logs_agent_trusted_profile_id = module.trusted_profile.trusted_profile.id
  logs_agent_namespace          = local.logs_agent_namespace
  logs_agent_name               = local.logs_agent_name
  cloud_logs_ingress_endpoint   = module.ocp_cluster_with_add_ons.cloud_logs_ingress_private_endpoint
  cloud_logs_ingress_port       = 3443
  # example of how to add additional metadata to the logs agent
  logs_agent_additional_metadata = [{
    key   = "cluster_id"
    value = module.ocp_cluster_with_add_ons.cluster_id
  }]
  logs_agent_resources = {
    limits = {
      cpu    = "500m"
      memory = "3Gi"
    }
    requests = {
      cpu    = "100m"
      memory = "1Gi"
    }
  }
  # example of how to add additional log source path
  logs_agent_system_logs = ["/logs/*.log"]
}
