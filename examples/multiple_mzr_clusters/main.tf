###############################################################################
# Resource Group
###############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

###############################################################################
# VPC
###############################################################################

# module "acl_profile" {
#   source = "git::https://github.ibm.com/GoldenEye/acl-profile-ocp.git?ref=1.1.2"
# }

# locals {
#   acl_rules_map = {
#     private = concat(
#       module.acl_profile.base_acl,
#       module.acl_profile.https_acl,
#       module.acl_profile.deny_all_acl
#     )
#   }
#   vpc_cidr_bases = {
#     private = "192.168.0.0/20",
#     transit = "192.168.16.0/20",
#     edge    = "192.168.32.0/20"
#   }
# }

# module "vpc" {
#   source                    = "git::https://github.ibm.com/GoldenEye/vpc-module.git?ref=5.3.0"
#   unique_name               = var.prefix
#   ibm_region                = var.region
#   resource_group_id         = module.resource_group.resource_group_id
#   cidr_bases                = local.vpc_cidr_bases
#   acl_rules_map             = local.acl_rules_map
#   virtual_private_endpoints = {}
#   vpc_tags                  = var.resource_tags
# }

# ---------------------------------------------------------------------------------------------------------------------
# Base OCP Clusters
# ---------------------------------------------------------------------------------------------------------------------

module "ocp_base_cluster_1" {
  source               = "../.."
  cluster_name         = "${var.prefix}-cluster-1"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = module.vpc.subnets
  worker_pools         = var.worker_pools
  worker_pools_taints  = var.worker_pools_taints
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  ibmcloud_api_key     = var.ibmcloud_api_key
}

module "ocp_base_cluster_2" {
  source               = "../.."
  cluster_name         = "${var.prefix}-cluster-2"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = module.vpc.subnets
  worker_pools         = var.worker_pools
  worker_pools_taints  = var.worker_pools_taints
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  ibmcloud_api_key     = var.ibmcloud_api_key
}

###############################################################################
# Init cluster config for helm and kubernetes providers
###############################################################################
data "ibm_container_cluster_config" "cluster_config_c1" {
  cluster_name_id   = module.ocp_base_cluster_1.cluster_id
  resource_group_id = module.ocp_base_cluster_1.resource_group_id
}

data "ibm_container_cluster_config" "cluster_config_c2" {
  cluster_name_id   = module.ocp_base_cluster_2.cluster_id
  resource_group_id = module.ocp_base_cluster_2.resource_group_id
}

###############################################################################
# Cluster Proxy - THis has to be replaced with something else usig helm??
###############################################################################

module "proxy_cluster_1" {
  source = "git::https://github.ibm.com/GoldenEye/cluster-proxy-module.git?ref=2.4.52"
  providers = {
    helm = helm.helm_cluster_1
  }
  cluster_id = module.ocp_base_cluster_1.cluster_id
}

module "proxy_cluster_2" {
  source = "git::https://github.ibm.com/GoldenEye/cluster-proxy-module.git?ref=2.4.52"
  providers = {
    helm = helm.helm_cluster_2
  }
  cluster_id = module.ocp_base_cluster_2.cluster_id
}
