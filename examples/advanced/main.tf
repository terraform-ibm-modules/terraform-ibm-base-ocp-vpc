########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# Key Protect
########################################################################################################################

locals {
  key_ring        = "ocp"
  cluster_key     = "${var.prefix}-cluster-data-encryption-key"
  boot_volume_key = "${var.prefix}-boot-volume-encryption-key"
}

module "kp_all_inclusive" {
  source                    = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                   = "4.16.7"
  key_protect_instance_name = "${var.prefix}-kp-instance"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  resource_tags             = var.resource_tags
  keys = [{
    key_ring_name = local.key_ring
    keys = [
      {
        key_name     = local.cluster_key
        force_delete = true
      },
      {
        key_name     = local.boot_volume_key
        force_delete = true
      }
    ]
  }]
}

########################################################################################################################
# VPC
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

########################################################################################################################
# Public Gateway in zone 1 only
########################################################################################################################

resource "ibm_is_public_gateway" "gateway" {
  for_each       = toset(["1", "2", "3"])
  name           = "${var.prefix}-gateway-${each.key}"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-${each.key}"
}

########################################################################################################################
# Subnets accross 3 zones
# Public gateway attached to all the zones
########################################################################################################################

resource "ibm_is_subnet" "subnets" {
  for_each                 = toset(["1", "2", "3"])
  name                     = "${var.prefix}-subnet-${each.key}"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-${each.key}"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway[each.key].id
}

########################################################################################################################
# 3 zone OCP VPC cluster
########################################################################################################################

locals {
  # list of subnets in all zones
  subnets = [
    for subnet in ibm_is_subnet.subnets :
    {
      id         = subnet.id
      zone       = subnet.zone
      cidr_block = subnet.ipv4_cidr_block
    }
  ]

  # mapping of cluster worker pool names to subnets
  cluster_vpc_subnets = {
    zone-1 = local.subnets,
    zone-2 = local.subnets,
    zone-3 = local.subnets
  }

  boot_volume_encryption_kms_config = {
    crk             = module.kp_all_inclusive.keys["${local.key_ring}.${local.boot_volume_key}"].key_id
    kms_instance_id = module.kp_all_inclusive.kms_guid
  }

  worker_pools = [
    {
      subnet_prefix                     = "zone-1"
      pool_name                         = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type                      = "mx2.4x32"
      workers_per_zone                  = 1
      operating_system                  = "REDHAT_8_64"
      enableAutoscaling                 = true
      minSize                           = 1
      maxSize                           = 6
      boot_volume_encryption_kms_config = local.boot_volume_encryption_kms_config
    },
    {
      subnet_prefix                     = "zone-2"
      pool_name                         = "zone-2"
      machine_type                      = "bx2.4x16"
      workers_per_zone                  = 1
      secondary_storage                 = "300gb.5iops-tier"
      operating_system                  = "REDHAT_8_64"
      boot_volume_encryption_kms_config = local.boot_volume_encryption_kms_config
    },
    {
      subnet_prefix                     = "zone-3"
      pool_name                         = "zone-3"
      machine_type                      = "bx2.4x16"
      workers_per_zone                  = 1
      operating_system                  = "REDHAT_8_64"
      boot_volume_encryption_kms_config = local.boot_volume_encryption_kms_config
    }
  ]

  worker_pools_taints = {
    all     = []
    default = []
    zone-2 = [{
      key    = "dedicated"
      value  = "zone-2"
      effect = "NoExecute"
    }]
    zone-3 = [{
      key    = "dedicated"
      value  = "zone-3"
      effect = "NoExecute"
    }]
  }
}

module "ocp_base" {
  source               = "../.."
  cluster_name         = var.prefix
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = ibm_is_vpc.vpc.id
  vpc_subnets          = local.cluster_vpc_subnets
  worker_pools         = local.worker_pools
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  access_tags          = var.access_tags
  worker_pools_taints  = local.worker_pools_taints
  ocp_entitlement      = var.ocp_entitlement
  # Enable if using worker autoscaling. Stops Terraform managing worker count.
  ignore_worker_pool_size_changes = true
  addons = {
    "cluster-autoscaler" = "1.2.1"
  }
  kms_config = {
    instance_id = module.kp_all_inclusive.kms_guid
    crk_id      = module.kp_all_inclusive.keys["${local.key_ring}.${local.cluster_key}"].key_id
  }
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_base.cluster_id
  resource_group_id = module.ocp_base.resource_group_id
  config_dir        = "${path.module}/../../kubeconfig"
}
