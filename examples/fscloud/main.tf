locals {
  #  Validation
  #  Validate input worker pool inputs , must use private endpoints
}

##############################################################################
# Provision an OCP cluster with one extra worker pool inside a VPC
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

module "cos_fscloud" {
  source                        = "terraform-ibm-modules/cos/ibm"
  version                       = "6.10.0"
  resource_group_id             = module.resource_group.resource_group_id
  create_cos_bucket             = false
  cos_instance_name             = "${var.prefix}-cos"
  cos_tags                      = var.resource_tags
  skip_iam_authorization_policy = true

  sysdig_crn           = module.observability_instances.sysdig_crn
  activity_tracker_crn = local.at_crn
  # Don't set CBR rules here as we don't want to create a circular dependency with the VPC module
}

module "flowlogs_bucket" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "6.10.0"

  bucket_configs = [
    {
      bucket_name            = "${var.prefix}-vpc-flowlogs"
      kms_encryption_enabled = true
      kms_guid               = var.hpcs_instance_guid
      kms_key_crn            = var.hpcs_key_crn_cluster
      region_location        = var.region
      resource_instance_id   = module.cos_fscloud.cos_instance_id
      resource_group_id      = module.resource_group.resource_group_id
    }
  ]
}

##############################################################################
# VPC
##############################################################################
module "vpc" {
  depends_on                             = [module.flowlogs_bucket]
  source                                 = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version                                = "7.3.2"
  resource_group_id                      = module.resource_group.resource_group_id
  region                                 = var.region
  prefix                                 = var.prefix
  tags                                   = var.resource_tags
  name                                   = var.vpc_name
  address_prefixes                       = var.addresses
  clean_default_acl                      = true
  clean_default_security_group           = true
  enable_vpc_flow_logs                   = true
  create_authorization_policy_vpc_to_cos = true
  existing_storage_bucket_name           = module.flowlogs_bucket.bucket_configs[0].bucket_name
  security_group_rules                   = []
  existing_cos_instance_guid             = module.cos_fscloud.cos_instance_guid
  subnets                                = var.subnets
  use_public_gateways = {
    zone-1 = false
    zone-2 = false
    zone-3 = false
  }
  ibmcloud_api_key = var.ibmcloud_api_key
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
  source  = "terraform-ibm-modules/observability-instances/ibm"
  version = "2.7.0"
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
# Create CBR Zone and Rules
##############################################################################
module "cbr_zone" {
  source           = "terraform-ibm-modules/cbr/ibm//cbr-zone-module"
  version          = "1.2.0"
  name             = "${var.prefix}-VPC-network-zone"
  zone_description = "CBR Network zone containing VPC"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type  = "vpc", # to bind a specific vpc to the zone
    value = module.vpc.vpc_crn,
  }]
}

module "cbr_rules" {
  source           = "terraform-ibm-modules/cbr/ibm//cbr-rule-module"
  version          = "1.2.0"
  rule_description = "${var.prefix} rule for vpc flow log access to cos"
  enforcement_mode = "enabled"
  resources = [{
    attributes = [
      {
        name     = "accountId"
        value    = data.ibm_iam_account_settings.iam_account_settings.account_id
        operator = "stringEquals"
      },
      {
        name     = "resourceGroupId",
        value    = module.resource_group.resource_group_id
        operator = "stringEquals"
      },
      {
        name     = "serviceInstance"
        value    = module.cos_fscloud.cos_instance_id
        operator = "stringEquals"
      },
      {
        name     = "serviceName"
        value    = "cloud-object-storage"
        operator = "stringEquals"
      }
    ],
  }]
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
  source                          = "../../modules/fscloud"
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
