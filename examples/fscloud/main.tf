locals {
  #  Validation
  #  Validate input worker pool inputs , must use private endpoints
}

##############################################################################
# Provision an OCP cluster with one extra worker pool inside a VPC
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# VPC
##############################################################################
module "vpc" {
  source              = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=v5.0.1"
  resource_group_id   = module.resource_group.resource_group_id
  region              = var.region
  prefix              = var.prefix
  tags                = var.resource_tags
  name                = var.vpc_name
  address_prefixes    = var.addresses
  subnets             = var.subnets
  use_public_gateways = var.public_gateway
}

##############################################################################
# Observability Instances (Sysdig + AT)
##############################################################################

locals {
  existing_at = var.existing_at_instance_crn != null ? true : false
  at_crn      = var.existing_at_instance_crn == null ? module.observability_instances.activity_tracker_crn : var.existing_at_instance_crn
}

# Create Sysdig and Activity Tracker instance
module "observability_instances" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=v2.5.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  region                         = var.region
  resource_group_id              = module.resource_group.resource_group_id
  sysdig_instance_name           = "${var.prefix}-sysdig"
  sysdig_plan                    = "graduated-tier"
  enable_platform_logs           = false
  enable_platform_metrics        = false
  logdna_provision               = false
  activity_tracker_instance_name = "${var.prefix}-at"
  activity_tracker_tags          = var.resource_tags
  activity_tracker_plan          = "7-day"
  activity_tracker_provision     = !local.existing_at
  logdna_tags                    = var.resource_tags
  sysdig_tags                    = var.resource_tags
}

##############################################################################
# Get Cloud Account ID
##############################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}

##############################################################################
# Create CBR Zone
##############################################################################
module "cbr_zone" {
  source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cbr//cbr-zone-module?ref=v1.2.0"
  name             = "${var.prefix}-VPC-network-zone"
  zone_description = "CBR Network zone containing VPC"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type  = "vpc", # to bind a specific vpc to the zone
    value = module.vpc.vpc_crn,
  }]
}

module "cos_fscloud" {
  source                        = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cos?ref=v6.0.0"
  resource_group_id             = module.resource_group.resource_group_id
  cos_instance_name             = "${var.prefix}-cos"
  cos_tags                      = var.resource_tags
  create_cos_bucket             = false
  skip_iam_authorization_policy = true

  sysdig_crn           = module.observability_instances.sysdig_crn
  activity_tracker_crn = local.at_crn
  bucket_cbr_rules = [
    {
      description      = "sample rule for bucket 1"
      enforcement_mode = "report"
      account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
      rule_contexts = [{
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_zone.zone_id
        }]
      }]
    }
  ]
  instance_cbr_rules = [
    {
      description      = "sample rule for the instance"
      enforcement_mode = "report"
      account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
      rule_contexts = [{
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_zone.zone_id
        }]
      }]
    }
  ]
}

##############################################################################
# Base OCP Cluster
##############################################################################
locals {
  cluster_hpcs_worker_pool_key_id = regex("key:(.*)", var.hpcs_key_crn_worker_pool)[0]
  cluster_hpcs_cluster_key_id     = regex("key:(.*)", var.hpcs_key_crn_cluster)[0]
  cluster_vpc_subnets = {
    default = [
      for subnet in module.vpc.subnet_zone_list :
      {
        id         = subnet.id
        zone       = subnet.zone
        cidr_block = subnet.cidr
      }
    ]
  }

  worker_pools = [
    {
      subnet_prefix     = "default"
      pool_name         = "default" # ibm_container_vpc_cluster automatically names standard pool "standard" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      labels            = {}
      resource_group_id = module.resource_group.resource_group_id
      boot_volume_encryption_kms_config = {
        crk              = local.cluster_hpcs_worker_pool_key_id
        kms_instance_id  = var.hpcs_instance_guid
        private_endpoint = true
      }
    }
  ]
}

module "ocp_fscloud" {
  source                          = "../../profiles/fscloud"
  cluster_name                    = var.prefix
  ibmcloud_api_key                = var.ibmcloud_api_key
  resource_group_id               = module.resource_group.resource_group_id
  region                          = "us-south"
  force_delete_storage            = true
  vpc_id                          = module.vpc.vpc_id
  vpc_subnets                     = local.cluster_vpc_subnets
  existing_cos_id                 = module.cos_fscloud.cos_instance_id
  worker_pools                    = length(var.worker_pools) > 0 ? var.worker_pools : local.worker_pools
  verify_worker_network_readiness = var.verify_worker_network_readiness
  ocp_version                     = var.ocp_version
  tags                            = var.resource_tags
  kms_config = {
    instance_id      = var.hpcs_instance_guid
    crk_id           = local.cluster_hpcs_cluster_key_id
    private_endpoint = true
  }
}

##############################################################################
