##############################################################################
# Worker Pools
##############################################################################

locals {
  # all_standalone_pools are the pools managed by a 'standalone' ibm_container_vpc_worker_pool resource
  all_standalone_pools             = [for pool in var.worker_pools : pool if !var.ignore_worker_pool_size_changes]
  all_standalone_autoscaling_pools = [for pool in var.worker_pools : pool if var.ignore_worker_pool_size_changes]
  additional_pool_names            = var.ignore_worker_pool_size_changes ? [for pool in local.all_standalone_autoscaling_pools : pool.pool_name] : [for pool in local.all_standalone_pools : pool.pool_name]
  pool_names                       = toset(flatten([["default"], local.additional_pool_names]))
}

data "ibm_container_vpc_worker_pool" "all_pools" {
  depends_on       = [ibm_container_vpc_worker_pool.autoscaling_pool, ibm_container_vpc_worker_pool.pool]
  for_each         = local.pool_names
  cluster          = var.cluster_id
  worker_pool_name = each.value
}

resource "ibm_container_vpc_worker_pool" "pool" {
  for_each          = { for pool in local.all_standalone_pools : pool.pool_name => pool }
  vpc_id            = var.vpc_id
  resource_group_id = var.resource_group_id
  cluster           = var.cluster_id
  worker_pool_name  = each.value.pool_name
  flavor            = each.value.machine_type
  operating_system  = each.value.operating_system
  worker_count      = each.value.workers_per_zone
  secondary_storage = each.value.secondary_storage
  entitlement       = var.ocp_entitlement
  labels            = each.value.labels
  crk               = each.value.boot_volume_encryption_kms_config == null ? null : each.value.boot_volume_encryption_kms_config.crk
  kms_instance_id   = each.value.boot_volume_encryption_kms_config == null ? null : each.value.boot_volume_encryption_kms_config.kms_instance_id
  kms_account_id    = each.value.boot_volume_encryption_kms_config == null ? null : each.value.boot_volume_encryption_kms_config.kms_account_id

  security_groups = each.value.additional_security_group_ids

  dynamic "zones" {
    for_each = each.value.subnet_prefix != null ? var.vpc_subnets[each.value.subnet_prefix] : each.value.vpc_subnets
    content {
      subnet_id = zones.value.id
      name      = zones.value.zone
    }
  }

  # Apply taints to worker pools i.e. all_standalone_pools
  dynamic "taints" {
    for_each = var.worker_pools_taints == null ? [] : concat(var.worker_pools_taints["all"], lookup(var.worker_pools_taints, each.value["pool_name"], []))
    content {
      effect = taints.value.effect
      key    = taints.value.key
      value  = taints.value.value
    }
  }

  timeouts {
    # Extend create and delete timeout to 2h
    delete = "2h"
    create = "2h"
  }

  # The default workerpool has to be imported as it will already exist on cluster create
  import_on_create = each.value.pool_name == "default" ? var.allow_default_worker_pool_replacement ? null : true : null
  orphan_on_delete = each.value.pool_name == "default" ? var.allow_default_worker_pool_replacement ? null : true : null
}

# copy of the pool resource above which ignores changes to the worker pool for use in autoscaling scenarios
resource "ibm_container_vpc_worker_pool" "autoscaling_pool" {
  for_each          = { for pool in local.all_standalone_autoscaling_pools : pool.pool_name => pool }
  vpc_id            = var.vpc_id
  resource_group_id = var.resource_group_id
  cluster           = var.cluster_id
  worker_pool_name  = each.value.pool_name
  flavor            = each.value.machine_type
  operating_system  = each.value.operating_system
  worker_count      = each.value.workers_per_zone
  secondary_storage = each.value.secondary_storage
  entitlement       = var.ocp_entitlement
  labels            = each.value.labels
  crk               = each.value.boot_volume_encryption_kms_config == null ? null : each.value.boot_volume_encryption_kms_config.crk
  kms_instance_id   = each.value.boot_volume_encryption_kms_config == null ? null : each.value.boot_volume_encryption_kms_config.kms_instance_id
  kms_account_id    = each.value.boot_volume_encryption_kms_config == null ? null : each.value.boot_volume_encryption_kms_config.kms_account_id

  security_groups = each.value.additional_security_group_ids

  lifecycle {
    ignore_changes = [worker_count]
  }

  dynamic "zones" {
    for_each = each.value.subnet_prefix != null ? var.vpc_subnets[each.value.subnet_prefix] : each.value.vpc_subnets
    content {
      subnet_id = zones.value.id
      name      = zones.value.zone
    }
  }

  # Apply taints to worker pools i.e. all_standalone_pools

  dynamic "taints" {
    for_each = var.worker_pools_taints == null ? [] : concat(var.worker_pools_taints["all"], lookup(var.worker_pools_taints, each.value["pool_name"], []))
    content {
      effect = taints.value.effect
      key    = taints.value.key
      value  = taints.value.value
    }
  }

  # The default workerpool has to be imported as it will already exist on cluster create
  import_on_create = each.value.pool_name == "default" ? var.allow_default_worker_pool_replacement ? null : true : null
  orphan_on_delete = each.value.pool_name == "default" ? var.allow_default_worker_pool_replacement ? null : true : null
}
