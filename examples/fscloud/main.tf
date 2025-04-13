########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.2.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# COS instance
########################################################################################################################

module "cos_fscloud" {
  source                        = "terraform-ibm-modules/cos/ibm"
  version                       = "8.21.8"
  resource_group_id             = module.resource_group.resource_group_id
  create_cos_bucket             = false
  cos_instance_name             = "${var.prefix}-cos"
  skip_iam_authorization_policy = true
  # Don't set CBR rules here as we don't want to create a circular dependency with the VPC module
}

########################################################################################################################
# COS bucket for VPC Flow logs
########################################################################################################################

module "flowlogs_bucket" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "8.21.8"

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

########################################################################################################################
# VPC
########################################################################################################################

module "vpc" {
  depends_on        = [module.flowlogs_bucket]
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "7.22.9"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  tags              = []
  name              = "${var.prefix}-vpc"
  address_prefixes = {
    zone-1 = ["10.10.10.0/24"]
    zone-2 = ["10.20.10.0/24"]
    zone-3 = ["10.30.10.0/24"]
  }
  clean_default_sg_acl                   = true
  enable_vpc_flow_logs                   = true
  create_authorization_policy_vpc_to_cos = true
  existing_storage_bucket_name           = module.flowlogs_bucket.bucket_configs[0].bucket_name
  security_group_rules                   = []
  existing_cos_instance_guid             = module.cos_fscloud.cos_instance_guid
  subnets = {
    zone-1 = [
      {
        acl_name = "vpc-acl"
        name     = "zone-1"
        cidr     = "10.10.10.0/24"
      }
    ],
    zone-2 = [
      {
        acl_name = "vpc-acl"
        name     = "zone-2"
        cidr     = "10.20.10.0/24"
      }
    ],
    zone-3 = [
      {
        acl_name = "vpc-acl"
        name     = "zone-3"
        cidr     = "10.30.10.0/24"
      }
  ] }
  use_public_gateways = {
    zone-1 = false
    zone-2 = false
    zone-3 = false
  }
}

########################################################################################################################
# Get Cloud Account ID
########################################################################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}


########################################################################################################################
# Create CBR Zone and Rules
########################################################################################################################

module "cbr_vpc_zone" {
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-zone-module"
  version          = "1.29.0"
  name             = "${var.prefix}-VPC-network-zone"
  zone_description = "CBR Network zone representing VPC"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type  = "vpc", # to bind a specific vpc to the zone
    value = module.vpc.vpc_crn,
  }]
}

module "cbr_zone_schematics" {
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-zone-module"
  version          = "1.29.0"
  name             = "${var.prefix}-schematics-zone"
  zone_description = "CBR Network zone containing Schematics"
  account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
  addresses = [{
    type = "serviceRef",
    ref = {
      account_id   = data.ibm_iam_account_settings.iam_account_settings.account_id
      service_name = "schematics"
    }
  }]
}

module "cbr_rules" {
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module"
  version          = "1.29.0"
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
        value = module.cbr_vpc_zone.zone_id
    }]
  }]
}


########################################################################################################################
# OCP VPC Cluster
########################################################################################################################

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
      pool_name         = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      operating_system  = "RHCOS"
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

########################################################################################################################
# Security groups
# Creating some security group for illustration purpose in this example.
# Real-world sg would have your own rules set in the `security_group_rules` input.
########################################################################################################################

module "custom_sg" {
  for_each                     = toset(["custom-lb-sg"])
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "2.6.2"
  add_ibm_cloud_internal_rules = false
  security_group_name          = each.key
  security_group_rules         = []
  resource_group               = module.resource_group.resource_group_id
  vpc_id                       = module.vpc.vpc_id
}

module "ocp_fscloud" {
  source                           = "../../modules/fscloud"
  cluster_name                     = var.prefix
  resource_group_id                = module.resource_group.resource_group_id
  region                           = var.region
  force_delete_storage             = true
  vpc_id                           = module.vpc.vpc_id
  vpc_subnets                      = local.cluster_vpc_subnets
  existing_cos_id                  = module.cos_fscloud.cos_instance_id
  worker_pools                     = local.worker_pools
  tags                             = var.resource_tags
  access_tags                      = var.access_tags
  ocp_version                      = var.ocp_version
  additional_lb_security_group_ids = [module.custom_sg["custom-lb-sg"].security_group_id]
  use_private_endpoint             = true
  ocp_entitlement                  = var.ocp_entitlement
  enable_ocp_console               = false
  kms_config = {
    instance_id      = var.hpcs_instance_guid
    crk_id           = local.cluster_hpcs_cluster_key_id
    private_endpoint = true
  }
  cbr_rules = [
    {
      description      = "${var.prefix}-OCP-base access only from vpc"
      enforcement_mode = "enabled"
      account_id       = data.ibm_iam_account_settings.iam_account_settings.account_id
      rule_contexts = [{
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_vpc_zone.zone_id
        }]
        }, {
        attributes = [
          {
            "name" : "endpointType",
            "value" : "private"
          },
          {
            name  = "networkZoneId"
            value = module.cbr_zone_schematics.zone_id
        }]
      }]
      operations = [{
        api_types = [
          {
            "api_type_id" : "crn:v1:bluemix:public:containers-kubernetes::::api-type:management"
          }
        ]
      }]
    }

  ]

}
