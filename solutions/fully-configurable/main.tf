#######################################################################################################################
# Resource Group
#######################################################################################################################
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_resource_group == false ? ((var.prefix != null && var.prefix != "") ? "${var.prefix}-${var.resource_group_name}" : var.resource_group_name) : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################

locals {
  prefix = var.prefix != null ? (var.prefix != "" ? var.prefix : null) : null
}

data "ibm_is_subnets" "vpc_subnets" {
  vpc = var.existing_vpc_id
}

locals {
  cluster_vpc_subnets = {
    for subnet in data.ibm_is_subnets.vpc_subnets.subnets :
    "default" => [{
      id         = subnet.id
      zone       = subnet.zone
      cidr_block = subnet.ipv4_cidr_block
    }]
  }

  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default"
      machine_type     = var.machine_type
      workers_per_zone = var.number_worker_nodes
      operating_system = var.operating_system
    }
  ]
  
  kms_config = {
    instance_id      = var.instance_id
    crk_id           = var.crk_id
    private_endpoint = var.private_endpoint
    account_id=var.account_id
    wait_for_apply=var.wait_for_apply
  }
}

module "ocp_base" {
  source                                = "../.."
  resource_group_id                     = module.resource_group.resource_group_id
  region                                = var.region
  tags                                  = var.resource_tags
  cluster_name                          = try("${local.prefix}-${var.cluster_name}", var.cluster_name)
  force_delete_storage                  = var.force_delete_storage
  use_existing_cos                      = true
  existing_cos_id                       = var.existing_cos_instance_crn
  vpc_id                                = var.existing_vpc_id
  vpc_subnets                           = local.cluster_vpc_subnets
  ocp_version                           = var.ocp_version
  worker_pools                          = local.worker_pools
  access_tags                           = var.access_tags
  ocp_entitlement                       = var.ocp_entitlement
  additional_lb_security_group_ids      = var.additional_lb_security_group_ids
  additional_vpe_security_group_ids     = var.additional_vpe_security_group_ids
  addons                                = var.addons
  allow_default_worker_pool_replacement = var.allow_default_worker_pool_replacement
  attach_ibm_managed_security_group     = var.attach_ibm_managed_security_group
  cluster_config_endpoint_type          = var.cluster_config_endpoint_type
  cbr_rules                             = var.cbr_rules
  cluster_ready_when                    = var.cluster_ready_when
  custom_security_group_ids             = var.custom_security_group_ids
  disable_outbound_traffic_protection   = var.disable_outbound_traffic_protection
  disable_public_endpoint               = var.disable_public_endpoint
  enable_ocp_console                    = var.enable_ocp_console
  ignore_worker_pool_size_changes       = var.ignore_worker_pool_size_changes
  kms_config                            = local.kms_config
  manage_all_addons                     = var.manage_all_addons
  number_of_lbs                         = var.number_of_lbs
  pod_subnet_cidr                       = var.pod_subnet_cidr
  service_subnet_cidr                   = var.service_subnet_cidr
  use_private_endpoint                  = var.use_private_endpoint
  verify_worker_network_readiness       = var.verify_worker_network_readiness
  worker_pools_taints                   = var.worker_pools_taints
}
