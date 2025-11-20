##############################################################################
# base-ocp-vpc-module
# Deploy Openshift cluster in IBM Cloud on VPC Gen 2
##############################################################################

# Segregate pools, as we need default pool for cluster creation
locals {
  # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
  default_pool = element([for pool in var.worker_pools : pool if pool.pool_name == "default"], 0)

  default_ocp_version = "${data.ibm_container_cluster_versions.cluster_versions.default_openshift_version}_openshift"
  ocp_version         = var.ocp_version == null || var.ocp_version == "default" ? local.default_ocp_version : "${var.ocp_version}_openshift"

  cos_name = var.use_existing_cos == true || (var.use_existing_cos == false && var.cos_name != null) ? var.cos_name : "${var.cluster_name}_cos"
  cos_plan = "standard"
  # if not enable_registry_storage then set cos to 'null', otherwise use existing or new CRN
  cos_instance_crn = var.enable_registry_storage == true ? (var.use_existing_cos != false ? var.existing_cos_id : module.cos_instance[0].cos_instance_id) : null

  delete_timeout = "2h"
  create_timeout = "3h"
  update_timeout = "3h"

  # tflint-ignore: terraform_unused_declarations
  cluster_with_upgrade_id = var.ignore_worker_pool_size_changes ? try(ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade[0].id, null) : try(ibm_container_vpc_cluster.cluster_with_upgrade[0].id, null)
  # tflint-ignore: terraform_unused_declarations
  cluster_without_upgrade_id = var.ignore_worker_pool_size_changes ? try(ibm_container_vpc_cluster.autoscaling_cluster[0].id, null) : try(ibm_container_vpc_cluster.cluster[0].id, null)

  cluster_id = var.enable_openshift_version_upgrade ? local.cluster_with_upgrade_id : local.cluster_without_upgrade_id

  # tflint-ignore: terraform_unused_declarations
  cluster_with_upgrade_crn = var.ignore_worker_pool_size_changes ? try(ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade[0].crn, null) : try(ibm_container_vpc_cluster.cluster_with_upgrade[0].crn, null)
  # tflint-ignore: terraform_unused_declarations
  cluster_without_upgrade_crn = var.ignore_worker_pool_size_changes ? try(ibm_container_vpc_cluster.autoscaling_cluster[0].crn, null) : try(ibm_container_vpc_cluster.cluster[0].crn, null)

  cluster_crn = var.enable_openshift_version_upgrade ? local.cluster_with_upgrade_crn : local.cluster_without_upgrade_crn

  # security group attached to worker pool
  # the terraform provider / iks api take a security group id hardcoded to "cluster", so this pseudo-value is injected into the array based on attach_default_cluster_security_group
  # see https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-security-group&interface=ui#vpc-sg-cluster

  # attach_ibm_managed_security_group is true and custom_security_group_ids is not set => default behavior, so set to null
  # attach_ibm_managed_security_group is true and custom_security_group_ids is set => add "cluster" to the list of custom security group ids

  # attach_ibm_managed_security_group is false and custom_security_group_ids is not set => default behavior, so set to null
  # attach_ibm_managed_security_group is false and custom_security_group_ids is set => only use the custom security group ids
  cluster_security_groups = var.attach_ibm_managed_security_group == true ? (var.custom_security_group_ids == null ? null : concat(["cluster"], var.custom_security_group_ids)) : (var.custom_security_group_ids == null ? null : var.custom_security_group_ids)

  # for versions older than 4.15, this value must be null, or provider gives error
  disable_outbound_traffic_protection = startswith(local.ocp_version, "4.14") ? null : var.disable_outbound_traffic_protection
}

# Local block to verify validations for OCP AI Addon.
locals {

  # retrieve worker specs (CPU & RAM) for all worker pools
  worker_specs = {
    for pool in var.worker_pools :
    pool.pool_name => {
      cpu_count = tonumber(regex("^.*?(\\d+)x(\\d+)", pool.machine_type)[0])
      ram_count = tonumber(regex("^.*?(\\d+)x(\\d+)", pool.machine_type)[1])
      is_gpu    = contains(["gx2", "gx3", "gx4"], split(".", pool.machine_type)[0])
    }
  }
}

# Separate local block to handle os validations
locals {
  os_rhel  = "REDHAT_8_64"
  os_rhcos = "RHCOS"
  os_rhel9 = "RHEL_9_64"

  # Strip OCP VERSION and use this ocp version in logic
  ocp_version_num  = regex("^([0-9]+\\.[0-9]+)", local.ocp_version)[0]
  is_valid_version = local.ocp_version_num != null ? tonumber(local.ocp_version_num) >= 4.15 : false

  rhcos_allowed_ocp_version = local.default_pool.operating_system == local.os_rhcos && local.is_valid_version

  worker_pool_rhcos_entry = [for worker in var.worker_pools : contains([local.os_rhel, local.os_rhel9], worker.operating_system) || (worker.operating_system == local.os_rhcos && local.is_valid_version) ? true : false]


  # To verify rhcos operating system exists only for OCP versions >=4.15
  # tflint-ignore: terraform_unused_declarations
  cluster_rhcos_validation = contains([local.os_rhel9, local.os_rhel], local.default_pool.operating_system) || local.rhcos_allowed_ocp_version ? true : tobool("RHCOS requires VPC clusters created from 4.15 onwards. Upgraded clusters from 4.14 cannot use RHCOS")

  # tflint-ignore: terraform_unused_declarations
  worker_pool_rhcos_validation = alltrue(local.worker_pool_rhcos_entry) ? true : tobool("RHCOS requires VPC clusters created from 4.15 onwards. Upgraded clusters from 4.14 cannot use RHCOS")

  # Validate if default worker pool's operating system is RHEL, all pools' operating system must be RHEL

  rhel_check_for_all_standalone_pools = [for pool in var.worker_pools : contains([local.os_rhel, local.os_rhel9], pool.operating_system) if pool.pool_name != "default"]

  # tflint-ignore: terraform_unused_declarations
  valid_rhel_worker_pools = local.default_pool.operating_system == local.os_rhcos || (contains([local.os_rhel, local.os_rhel9], local.default_pool.operating_system) && alltrue(local.rhel_check_for_all_standalone_pools)) ? true : tobool("Choosing RHEL for the default worker pool will limit all additional worker pools to RHEL.")

  # Validate if RHCOS is used as operating system for the cluster then the default worker pool must be created with RHCOS
  rhcos_check = contains([local.os_rhel, local.os_rhel9], local.default_pool.operating_system) || (local.default_pool.operating_system == local.os_rhcos && local.default_pool.operating_system == local.os_rhcos)

  # tflint-ignore: terraform_unused_declarations
  default_wp_validation = local.rhcos_check ? true : tobool("If RHCOS is used with this cluster, the default worker pool should be created with RHCOS.")
}

# Lookup the current default kube version
data "ibm_container_cluster_versions" "cluster_versions" {
  resource_group_id = var.resource_group_id
}

module "cos_instance" {
  count = var.enable_registry_storage && !var.use_existing_cos ? 1 : 0

  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "10.5.11"
  cos_instance_name      = local.cos_name
  resource_group_id      = var.resource_group_id
  cos_plan               = local.cos_plan
  kms_encryption_enabled = false
  create_cos_bucket      = false
}

moved {
  from = ibm_resource_instance.cos_instance[0]
  to   = module.cos_instance[0].ibm_resource_instance.cos_instance[0]
}

resource "ibm_resource_tag" "cos_access_tag" {
  count       = var.enable_registry_storage && !var.use_existing_cos && length(var.access_tags) > 0 ? 1 : 0
  resource_id = module.cos_instance[0].cos_instance_id
  tags        = var.access_tags
  tag_type    = "access"
  lifecycle {
    precondition {
      condition = alltrue([
        for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
      ])
      error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits for more details"
    }
  }
}

##############################################################################
# Create a OCP Cluster
##############################################################################

resource "ibm_container_vpc_cluster" "cluster" {
  count                               = var.enable_openshift_version_upgrade ? 0 : (var.ignore_worker_pool_size_changes ? 0 : 1)
  name                                = var.cluster_name
  vpc_id                              = var.vpc_id
  tags                                = var.tags
  kube_version                        = local.ocp_version
  flavor                              = local.default_pool.machine_type
  entitlement                         = var.ocp_entitlement
  cos_instance_crn                    = local.cos_instance_crn
  worker_count                        = local.default_pool.workers_per_zone
  resource_group_id                   = var.resource_group_id
  wait_till                           = var.cluster_ready_when
  force_delete_storage                = var.force_delete_storage
  secondary_storage                   = local.default_pool.secondary_storage
  pod_subnet                          = var.pod_subnet_cidr
  service_subnet                      = var.service_subnet_cidr
  operating_system                    = local.default_pool.operating_system
  disable_public_service_endpoint     = var.disable_public_endpoint
  worker_labels                       = local.default_pool.labels
  disable_outbound_traffic_protection = local.disable_outbound_traffic_protection
  crk                                 = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.crk
  kms_instance_id                     = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.kms_instance_id
  kms_account_id                      = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.kms_account_id

  security_groups = local.cluster_security_groups

  lifecycle {
    ignore_changes = [kube_version]
    precondition {
      condition     = var.custom_security_group_ids == null ? true : length(var.custom_security_group_ids) <= 4
      error_message = "Please provide at most 4 additional security groups."
    }
    precondition {
      condition = anytrue([
        var.ocp_version == null,
        var.ocp_version == "default",
        var.ocp_version == "4.14",
        var.ocp_version == "4.15",
        var.ocp_version == "4.16",
        var.ocp_version == "4.17",
        var.ocp_version == "4.18",
        var.ocp_version == "4.19",
      ])
      error_message = "The specified ocp_version is not of the valid versions."
    }
    precondition {
      condition     = contains(["MasterNodeReady", "OneWorkerNodeReady", "Normal", "IngressReady"], var.cluster_ready_when)
      error_message = "The input variable cluster_ready_when must be one of the following: \"MasterNodeReady\", \"OneWorkerNodeReady\", \"Normal\" or \"IngressReady\"."
    }
    precondition {
      condition     = !(var.enable_registry_storage && var.use_existing_cos && var.existing_cos_id == null)
      error_message = "A value for 'existing_cos_id' must be provided when 'enable_registry_storage' and 'use_existing_cos' are both set to true."
    }
    precondition {
      error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
      condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
    }
    precondition {
      condition     = var.number_of_lbs >= 1
      error_message = "Please set the number_of_lbs to a minimum of 1."
    }

    postcondition {
      condition     = self.master_status == "Ready"
      error_message = "Master status is ${self.master_status}, expected Ready."
    }
  }

  # default workers are mapped to the subnets that are "private"
  dynamic "zones" {
    for_each = local.default_pool.subnet_prefix != null ? var.vpc_subnets[local.default_pool.subnet_prefix] : local.default_pool.vpc_subnets
    content {
      subnet_id = zones.value.id
      name      = zones.value.zone
    }
  }

  # Apply taints to the default worker pools i.e private

  dynamic "taints" {
    for_each = var.worker_pools_taints == null ? [] : concat(var.worker_pools_taints["all"], var.worker_pools_taints["default"])
    content {
      effect = taints.value.effect
      key    = taints.value.key
      value  = taints.value.value
    }
  }

  dynamic "kms_config" {
    for_each = var.kms_config != null ? [1] : []
    content {
      crk_id           = var.kms_config.crk_id
      instance_id      = var.kms_config.instance_id
      private_endpoint = var.kms_config.private_endpoint == null ? true : var.kms_config.private_endpoint
      account_id       = var.kms_config.account_id
      wait_for_apply   = var.kms_config.wait_for_apply
    }
  }

  timeouts {
    # Extend create, update and delete timeout to static values.
    delete = local.delete_timeout
    create = local.create_timeout
    update = local.update_timeout
  }
}

# copy of the cluster resource above which allows major openshift version upgrade
resource "ibm_container_vpc_cluster" "cluster_with_upgrade" {
  count                               = var.enable_openshift_version_upgrade ? (var.ignore_worker_pool_size_changes ? 0 : 1) : 0
  name                                = var.cluster_name
  vpc_id                              = var.vpc_id
  tags                                = var.tags
  kube_version                        = local.ocp_version
  flavor                              = local.default_pool.machine_type
  entitlement                         = var.ocp_entitlement
  cos_instance_crn                    = local.cos_instance_crn
  worker_count                        = local.default_pool.workers_per_zone
  resource_group_id                   = var.resource_group_id
  wait_till                           = var.cluster_ready_when
  force_delete_storage                = var.force_delete_storage
  secondary_storage                   = local.default_pool.secondary_storage
  pod_subnet                          = var.pod_subnet_cidr
  service_subnet                      = var.service_subnet_cidr
  operating_system                    = local.default_pool.operating_system
  disable_public_service_endpoint     = var.disable_public_endpoint
  worker_labels                       = local.default_pool.labels
  disable_outbound_traffic_protection = local.disable_outbound_traffic_protection
  crk                                 = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.crk
  kms_instance_id                     = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.kms_instance_id
  kms_account_id                      = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.kms_account_id

  security_groups = local.cluster_security_groups

  lifecycle {
    precondition {
      condition     = var.custom_security_group_ids == null ? true : length(var.custom_security_group_ids) <= 4
      error_message = "Please provide at most 4 additional security groups."
    }
    precondition {
      condition = anytrue([
        var.ocp_version == null,
        var.ocp_version == "default",
        var.ocp_version == "4.14",
        var.ocp_version == "4.15",
        var.ocp_version == "4.16",
        var.ocp_version == "4.17",
        var.ocp_version == "4.18",
        var.ocp_version == "4.19",
      ])
      error_message = "The specified ocp_version is not of the valid versions."
    }
    precondition {
      condition     = contains(["MasterNodeReady", "OneWorkerNodeReady", "Normal", "IngressReady"], var.cluster_ready_when)
      error_message = "The input variable cluster_ready_when must be one of the following: \"MasterNodeReady\", \"OneWorkerNodeReady\", \"Normal\" or \"IngressReady\"."
    }
    precondition {
      condition     = !(var.enable_registry_storage && var.use_existing_cos && var.existing_cos_id == null)
      error_message = "A value for 'existing_cos_id' must be provided when 'enable_registry_storage' and 'use_existing_cos' are both set to true."
    }
    precondition {
      error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
      condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
    }
    precondition {
      condition     = var.number_of_lbs >= 1
      error_message = "Please set the number_of_lbs to a minimum of 1."
    }

    postcondition {
      condition     = self.master_status == "Ready"
      error_message = "Master status is ${self.master_status}, expected Ready."
    }
  }

  # This resource intentionally omits ignore_changes for kube_version to allow major version upgrades

  # default workers are mapped to the subnets that are "private"
  dynamic "zones" {
    for_each = local.default_pool.subnet_prefix != null ? var.vpc_subnets[local.default_pool.subnet_prefix] : local.default_pool.vpc_subnets
    content {
      subnet_id = zones.value.id
      name      = zones.value.zone
    }
  }

  # Apply taints to the default worker pools i.e private

  dynamic "taints" {
    for_each = var.worker_pools_taints == null ? [] : concat(var.worker_pools_taints["all"], var.worker_pools_taints["default"])
    content {
      effect = taints.value.effect
      key    = taints.value.key
      value  = taints.value.value
    }
  }

  dynamic "kms_config" {
    for_each = var.kms_config != null ? [1] : []
    content {
      crk_id           = var.kms_config.crk_id
      instance_id      = var.kms_config.instance_id
      private_endpoint = var.kms_config.private_endpoint == null ? true : var.kms_config.private_endpoint
      account_id       = var.kms_config.account_id
      wait_for_apply   = var.kms_config.wait_for_apply
    }
  }

  timeouts {
    # Extend create, update and delete timeout to static values.
    delete = local.delete_timeout
    create = local.create_timeout
    update = local.update_timeout
  }
}


# copy of the cluster resource above which ignores changes to the worker pool for use in autoscaling scenarios
resource "ibm_container_vpc_cluster" "autoscaling_cluster" {
  count                               = var.enable_openshift_version_upgrade ? 0 : (var.ignore_worker_pool_size_changes ? 1 : 0)
  name                                = var.cluster_name
  vpc_id                              = var.vpc_id
  tags                                = var.tags
  kube_version                        = local.ocp_version
  flavor                              = local.default_pool.machine_type
  entitlement                         = var.ocp_entitlement
  cos_instance_crn                    = local.cos_instance_crn
  worker_count                        = local.default_pool.workers_per_zone
  resource_group_id                   = var.resource_group_id
  wait_till                           = var.cluster_ready_when
  force_delete_storage                = var.force_delete_storage
  operating_system                    = local.default_pool.operating_system
  secondary_storage                   = local.default_pool.secondary_storage
  pod_subnet                          = var.pod_subnet_cidr
  service_subnet                      = var.service_subnet_cidr
  disable_public_service_endpoint     = var.disable_public_endpoint
  worker_labels                       = local.default_pool.labels
  disable_outbound_traffic_protection = local.disable_outbound_traffic_protection
  crk                                 = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.crk
  kms_instance_id                     = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.kms_instance_id
  kms_account_id                      = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.kms_account_id

  security_groups = local.cluster_security_groups

  lifecycle {
    ignore_changes = [worker_count, kube_version]
    precondition {
      condition     = var.custom_security_group_ids == null ? true : length(var.custom_security_group_ids) <= 4
      error_message = "Please provide at most 4 additional security groups."
    }
    precondition {
      condition = anytrue([
        var.ocp_version == null,
        var.ocp_version == "default",
        var.ocp_version == "4.14",
        var.ocp_version == "4.15",
        var.ocp_version == "4.16",
        var.ocp_version == "4.17",
        var.ocp_version == "4.18",
        var.ocp_version == "4.19",
      ])
      error_message = "The specified ocp_version is not of the valid versions."
    }
    precondition {
      condition     = contains(["MasterNodeReady", "OneWorkerNodeReady", "Normal", "IngressReady"], var.cluster_ready_when)
      error_message = "The input variable cluster_ready_when must be one of the following: \"MasterNodeReady\", \"OneWorkerNodeReady\", \"Normal\" or \"IngressReady\"."
    }
    precondition {
      condition     = !(var.enable_registry_storage && var.use_existing_cos && var.existing_cos_id == null)
      error_message = "A value for 'existing_cos_id' must be provided when 'enable_registry_storage' and 'use_existing_cos' are both set to true."
    }
    precondition {
      error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
      condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
    }
    precondition {
      condition     = var.number_of_lbs >= 1
      error_message = "Please set the number_of_lbs to a minimum of 1."
    }

    postcondition {
      condition     = self.master_status == "Ready"
      error_message = "Master status is ${self.master_status}, expected Ready."
    }
  }

  # default workers are mapped to the subnets that are "private"
  dynamic "zones" {
    for_each = local.default_pool.subnet_prefix != null ? var.vpc_subnets[local.default_pool.subnet_prefix] : local.default_pool.vpc_subnets
    content {
      subnet_id = zones.value.id
      name      = zones.value.zone
    }
  }

  # Apply taints to the default worker pools i.e private

  dynamic "taints" {
    for_each = var.worker_pools_taints == null ? [] : concat(var.worker_pools_taints["all"], var.worker_pools_taints["default"])
    content {
      effect = taints.value.effect
      key    = taints.value.key
      value  = taints.value.value
    }
  }

  dynamic "kms_config" {
    for_each = var.kms_config != null ? [1] : []
    content {
      crk_id           = var.kms_config.crk_id
      instance_id      = var.kms_config.instance_id
      private_endpoint = var.kms_config.private_endpoint
      account_id       = var.kms_config.account_id
      wait_for_apply   = var.kms_config.wait_for_apply
    }
  }

  timeouts {
    # Extend create, update and delete timeout to static values.
    delete = local.delete_timeout
    create = local.create_timeout
    update = local.update_timeout
  }
}

# copy of the cluster resource above which allows major openshift version upgrade
resource "ibm_container_vpc_cluster" "autoscaling_cluster_with_upgrade" {
  count                               = var.enable_openshift_version_upgrade ? (var.ignore_worker_pool_size_changes ? 1 : 0) : 0
  name                                = var.cluster_name
  vpc_id                              = var.vpc_id
  tags                                = var.tags
  kube_version                        = local.ocp_version
  flavor                              = local.default_pool.machine_type
  entitlement                         = var.ocp_entitlement
  cos_instance_crn                    = local.cos_instance_crn
  worker_count                        = local.default_pool.workers_per_zone
  resource_group_id                   = var.resource_group_id
  wait_till                           = var.cluster_ready_when
  force_delete_storage                = var.force_delete_storage
  operating_system                    = local.default_pool.operating_system
  secondary_storage                   = local.default_pool.secondary_storage
  pod_subnet                          = var.pod_subnet_cidr
  service_subnet                      = var.service_subnet_cidr
  disable_public_service_endpoint     = var.disable_public_endpoint
  worker_labels                       = local.default_pool.labels
  disable_outbound_traffic_protection = local.disable_outbound_traffic_protection
  crk                                 = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.crk
  kms_instance_id                     = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.kms_instance_id
  kms_account_id                      = local.default_pool.boot_volume_encryption_kms_config == null ? null : local.default_pool.boot_volume_encryption_kms_config.kms_account_id

  security_groups = local.cluster_security_groups

  # This resource intentionally omits ignore_changes for kube_version to allow major version upgrades

  lifecycle {
    ignore_changes = [worker_count]
    precondition {
      condition     = var.custom_security_group_ids == null ? true : length(var.custom_security_group_ids) <= 4
      error_message = "Please provide at most 4 additional security groups."
    }
    precondition {
      condition = anytrue([
        var.ocp_version == null,
        var.ocp_version == "default",
        var.ocp_version == "4.14",
        var.ocp_version == "4.15",
        var.ocp_version == "4.16",
        var.ocp_version == "4.17",
        var.ocp_version == "4.18",
        var.ocp_version == "4.19",
      ])
      error_message = "The specified ocp_version is not of the valid versions."
    }
    precondition {
      condition     = contains(["MasterNodeReady", "OneWorkerNodeReady", "Normal", "IngressReady"], var.cluster_ready_when)
      error_message = "The input variable cluster_ready_when must be one of the following: \"MasterNodeReady\", \"OneWorkerNodeReady\", \"Normal\" or \"IngressReady\"."
    }
    precondition {
      condition     = !(var.enable_registry_storage && var.use_existing_cos && var.existing_cos_id == null)
      error_message = "A value for 'existing_cos_id' must be provided when 'enable_registry_storage' and 'use_existing_cos' are both set to true."
    }
    precondition {
      error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
      condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
    }
    precondition {
      condition     = var.number_of_lbs >= 1
      error_message = "Please set the number_of_lbs to a minimum of 1."
    }

    postcondition {
      condition     = self.master_status == "Ready"
      error_message = "Master status is ${self.master_status}, expected Ready."
    }

  }

  # default workers are mapped to the subnets that are "private"
  dynamic "zones" {
    for_each = local.default_pool.subnet_prefix != null ? var.vpc_subnets[local.default_pool.subnet_prefix] : local.default_pool.vpc_subnets
    content {
      subnet_id = zones.value.id
      name      = zones.value.zone
    }
  }

  # Apply taints to the default worker pools i.e private

  dynamic "taints" {
    for_each = var.worker_pools_taints == null ? [] : concat(var.worker_pools_taints["all"], var.worker_pools_taints["default"])
    content {
      effect = taints.value.effect
      key    = taints.value.key
      value  = taints.value.value
    }
  }

  dynamic "kms_config" {
    for_each = var.kms_config != null ? [1] : []
    content {
      crk_id           = var.kms_config.crk_id
      instance_id      = var.kms_config.instance_id
      private_endpoint = var.kms_config.private_endpoint
      account_id       = var.kms_config.account_id
      wait_for_apply   = var.kms_config.wait_for_apply
    }
  }

  timeouts {
    # Extend create, update and delete timeout to static values.
    delete = local.delete_timeout
    create = local.create_timeout
    update = local.update_timeout
  }
}

##############################################################################
# Cluster Access Tag
##############################################################################

resource "ibm_resource_tag" "cluster_access_tag" {
  count       = length(var.access_tags) == 0 ? 0 : 1
  resource_id = local.cluster_crn
  tags        = var.access_tags
  tag_type    = "access"
  lifecycle {
    precondition {
      condition = alltrue([
        for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
      ])
      error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits for more details"
    }
  }
}

##############################################################################
# Access cluster to kick off RBAC synchronisation
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  count             = var.enable_ocp_console != null || var.verify_worker_network_readiness || lookup(var.addons, "cluster-autoscaler", null) != null ? 1 : 0
  cluster_name_id   = local.cluster_id
  config_dir        = "${path.module}/kubeconfig"
  admin             = true # workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/issues/374
  resource_group_id = var.resource_group_id
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null value represents default
}

module "worker_pools" {
  source                                = "./modules/worker-pool"
  vpc_id                                = var.vpc_id
  resource_group_id                     = var.resource_group_id
  cluster_id                            = local.cluster_id
  vpc_subnets                           = var.vpc_subnets
  worker_pools                          = var.worker_pools
  ignore_worker_pool_size_changes       = var.ignore_worker_pool_size_changes
  allow_default_worker_pool_replacement = var.allow_default_worker_pool_replacement
}

##############################################################################
# Confirm network healthy by ensuring master can communicate with all workers.
#
# Please note:
# The network health check is applicable only if the cluster is accessible.
#
# To do this, we run a script to execute "kubectl logs" against each calico
# daemonset pod (as there will be one pod per node) and ensure it passes.
#
# Why?
# There can be a delay in getting the routes set up for the VPN that lets
# the master connect across accounts down to the workers, and that VPN
# connection is what is used by "kubectl logs".
#
# Why is there a delay?
# The network microservice has to trigger on new workers being created and
# push down an updated vpn config, and then the vpn server and client need
# to pick up this updated config. Depending on how busy the network
# microservice is handling requests, there might be a delay.

##############################################################################

resource "null_resource" "confirm_network_healthy" {

  count = var.verify_worker_network_readiness ? 1 : 0

  # Worker pool creation can start before the 'ibm_container_vpc_cluster' completes since there is no explicit
  # depends_on in 'ibm_container_vpc_worker_pool', just an implicit depends_on on the cluster ID. Cluster ID can exist before
  # 'ibm_container_vpc_cluster' completes, so hence need to add explicit depends on against 'ibm_container_vpc_cluster' here.
  depends_on = [ibm_container_vpc_cluster.cluster, ibm_container_vpc_cluster.cluster_with_upgrade, ibm_container_vpc_cluster.autoscaling_cluster, ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade, module.worker_pools]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm_network_healthy.sh"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config[0].config_file_path
    }
  }
}

##############################################################################
# Enable or Disable OCP Console Patch
##############################################################################
resource "null_resource" "ocp_console_management" {
  count      = var.enable_ocp_console != null ? 1 : 0
  depends_on = [null_resource.confirm_network_healthy]
  provisioner "local-exec" {
    command     = "${path.module}/scripts/enable_disable_ocp_console.sh"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG         = data.ibm_container_cluster_config.cluster_config[0].config_file_path
      ENABLE_OCP_CONSOLE = var.enable_ocp_console
    }
  }
}

##############################################################################
# Addons
##############################################################################

# Lookup the current default csi-driver version
data "ibm_container_addons" "existing_addons" {
  cluster = local.cluster_id
}

locals {
  # for each cluster, look for installed csi driver to get version. If array is empty (no csi driver) then null is returned
  csi_driver_version = anytrue([for key, value in var.addons : true if key == "vpc-block-csi-driver" && value != null]) ? [var.addons["vpc-block-csi-driver"].version] : [
    for addon in data.ibm_container_addons.existing_addons.addons :
    addon.version if addon.name == "vpc-block-csi-driver"
  ]

  # get the addons and their versions and create an addons map including the corresponding csi_driver_version
  addons = merge(
    { for addon_name, addon_version in(var.addons != null ? var.addons : {}) : addon_name => addon_version if addon_version != null },
    length(local.csi_driver_version) > 0 ? { vpc-block-csi-driver = { version = local.csi_driver_version[0] } } : {}
  )
}

resource "ibm_container_addons" "addons" {
  # Worker pool creation can start before the 'ibm_container_vpc_cluster' completes since there is no explicit
  # depends_on in 'ibm_container_vpc_worker_pool', just an implicit depends_on on the cluster ID. Cluster ID can exist before
  # 'ibm_container_vpc_cluster' completes, so hence need to add explicit depends on against 'ibm_container_vpc_cluster' here.
  depends_on        = [ibm_container_vpc_cluster.cluster, ibm_container_vpc_cluster.cluster_with_upgrade, ibm_container_vpc_cluster.autoscaling_cluster, ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade, module.worker_pools, null_resource.confirm_network_healthy]
  cluster           = local.cluster_id
  resource_group_id = var.resource_group_id

  # setting to false means we do not want Terraform to manage addons that are managed elsewhere
  manage_all_addons = var.manage_all_addons

  dynamic "addons" {
    for_each = local.addons
    content {
      name            = addons.key
      version         = lookup(addons.value, "version", null)
      parameters_json = lookup(addons.value, "parameters_json", null)
    }
  }

  timeouts {
    create = "1h"
  }

  lifecycle {
    precondition {
      condition     = (lookup(var.addons, "openshift-ai", null) != null ? lookup(var.addons["openshift-ai"], "version", null) == null : true) || (tonumber(local.ocp_version_num) >= 4.16)
      error_message = "OCP AI add-on requires OCP version >= 4.16.0"
    }
    precondition {
      condition     = (lookup(var.addons, "openshift-ai", null) != null ? lookup(var.addons["openshift-ai"], "version", null) == null : true) || alltrue([for spec in values(local.worker_specs) : spec.cpu_count >= 8 && spec.ram_count >= 32])
      error_message = "To install OCP AI add-on, all worker nodes in all pools must have at least 8-core CPU and 32GB memory."
    }
    precondition {
      condition     = (lookup(var.addons, "openshift-ai", null) != null ? lookup(var.addons["openshift-ai"], "version", null) == null : true) || anytrue([for pool in var.worker_pools : lookup(local.worker_specs[pool.pool_name], "is_gpu", false)])
      error_message = "OCP AI add-on requires at least one GPU-enabled worker pool."
    }
  }
}

locals {
  worker_pool_config = [
    for worker in var.worker_pools :
    {
      name    = worker.pool_name
      minSize = worker.minSize
      maxSize = worker.maxSize
      enabled = worker.enableAutoscaling
    } if worker.enableAutoscaling != null && worker.minSize != null && worker.maxSize != null
  ]

}

resource "null_resource" "config_map_status" {
  count      = lookup(var.addons, "cluster-autoscaler", null) != null ? 1 : 0
  depends_on = [ibm_container_addons.addons]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/get_config_map_status.sh"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config[0].config_file_path
    }
  }
}

resource "kubernetes_config_map_v1_data" "set_autoscaling" {
  count      = lookup(var.addons, "cluster-autoscaler", null) != null ? 1 : 0
  depends_on = [null_resource.config_map_status]

  metadata {
    name      = "iks-ca-configmap"
    namespace = "kube-system"
  }

  data = {
    "workerPoolsConfig.json" = jsonencode(local.worker_pool_config)
  }

  force = true
}


##############################################################################
# Attach additional security groups to the load balancers managed by this
# cluster. Note that the module attaches security group to existing loadbalancer
# only. Re-run the module to attach security groups to new load balancers created
# after the initial run of this module. The module detects new load balancers.
# https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-security-group&interface=ui#vpc-sg-vpe-alb
##############################################################################

data "ibm_is_lbs" "all_lbs" {
  depends_on = [ibm_container_vpc_cluster.cluster, ibm_container_vpc_cluster.cluster_with_upgrade, ibm_container_vpc_cluster.autoscaling_cluster, ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade, module.worker_pools, null_resource.confirm_network_healthy]
  count      = length(var.additional_lb_security_group_ids) > 0 ? 1 : 0
}

locals {
  lbs_associated_with_cluster = length(var.additional_lb_security_group_ids) > 0 ? [for lb in data.ibm_is_lbs.all_lbs[0].load_balancers : lb.id if strcontains(lb.name, local.cluster_id)] : []
}

module "attach_sg_to_lb" {
  count                          = length(var.additional_lb_security_group_ids)
  source                         = "terraform-ibm-modules/security-group/ibm"
  version                        = "2.8.0"
  existing_security_group_id     = var.additional_lb_security_group_ids[count.index]
  use_existing_security_group_id = true
  target_ids                     = [for index in range(var.number_of_lbs) : local.lbs_associated_with_cluster[index]] # number_of_lbs is necessary to give a static number of elements to tf to accomplish the apply when the cluster does not initially exists
}


##############################################################################
# Attach additional security groups to the load balancers managed by this
# cluster. Note that the module attaches security group to existing loadbalancer
# only. Re-run the module to attach security groups to new load balancers created
# after the initial run of this module. The module detects new load balancers.
# https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-security-group&interface=ui#vpc-sg-vpe-alb
##############################################################################

locals {
  vpes_to_attach_to_sg = {
    "master" : "iks-${local.cluster_id}",
    "api" : "iks-api-${var.vpc_id}",
    "registry" : "iks-registry-${var.vpc_id}"
  }
}

data "ibm_is_virtual_endpoint_gateway" "master_vpe" {
  count      = length(var.additional_vpe_security_group_ids["master"])
  depends_on = [ibm_container_vpc_cluster.cluster, ibm_container_vpc_cluster.cluster_with_upgrade, ibm_container_vpc_cluster.autoscaling_cluster, ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade, module.worker_pools, null_resource.confirm_network_healthy]
  name       = local.vpes_to_attach_to_sg["master"]
}

data "ibm_is_virtual_endpoint_gateway" "api_vpe" {
  count      = length(var.additional_vpe_security_group_ids["api"])
  depends_on = [ibm_container_vpc_cluster.cluster, ibm_container_vpc_cluster.cluster_with_upgrade, ibm_container_vpc_cluster.autoscaling_cluster, ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade, module.worker_pools, null_resource.confirm_network_healthy]
  name       = local.vpes_to_attach_to_sg["api"]
}

data "ibm_is_virtual_endpoint_gateway" "registry_vpe" {
  count      = length(var.additional_vpe_security_group_ids["registry"])
  depends_on = [ibm_container_vpc_cluster.cluster, ibm_container_vpc_cluster.cluster_with_upgrade, ibm_container_vpc_cluster.autoscaling_cluster, ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade, module.worker_pools, null_resource.confirm_network_healthy]
  name       = local.vpes_to_attach_to_sg["registry"]
}

locals {
  # loading cluster master, cluster API and registry VPE IDs to attach related SGs
  master_vpe_id   = length(var.additional_vpe_security_group_ids["master"]) > 0 ? data.ibm_is_virtual_endpoint_gateway.master_vpe[0].id : null
  api_vpe_id      = length(var.additional_vpe_security_group_ids["api"]) > 0 ? data.ibm_is_virtual_endpoint_gateway.api_vpe[0].id : null
  registry_vpe_id = length(var.additional_vpe_security_group_ids["registry"]) > 0 ? data.ibm_is_virtual_endpoint_gateway.registry_vpe[0].id : null
}

module "attach_sg_to_master_vpe" {
  count                          = length(var.additional_vpe_security_group_ids["master"])
  source                         = "terraform-ibm-modules/security-group/ibm"
  version                        = "2.8.0"
  existing_security_group_id     = var.additional_vpe_security_group_ids["master"][count.index]
  use_existing_security_group_id = true
  target_ids                     = [local.master_vpe_id]
}

module "attach_sg_to_api_vpe" {
  count                          = length(var.additional_vpe_security_group_ids["api"])
  source                         = "terraform-ibm-modules/security-group/ibm"
  version                        = "2.8.0"
  existing_security_group_id     = var.additional_vpe_security_group_ids["api"][count.index]
  use_existing_security_group_id = true
  target_ids                     = [local.api_vpe_id]
}

module "attach_sg_to_registry_vpe" {
  count                          = length(var.additional_vpe_security_group_ids["registry"])
  source                         = "terraform-ibm-modules/security-group/ibm"
  version                        = "2.8.0"
  existing_security_group_id     = var.additional_vpe_security_group_ids["registry"][count.index]
  use_existing_security_group_id = true
  target_ids                     = [local.registry_vpe_id]
}

##############################################################################
# Context Based Restrictions
##############################################################################
locals {
  default_operations = [{
    api_types = [
      {
        "api_type_id" : "crn:v1:bluemix:public:context-based-restrictions::::api-type:"
      }
    ]
  }]
}
module "cbr_rule" {
  count            = length(var.cbr_rules) > 0 ? length(var.cbr_rules) : 0
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module"
  version          = "1.34.0"
  rule_description = var.cbr_rules[count.index].description
  enforcement_mode = var.cbr_rules[count.index].enforcement_mode
  rule_contexts    = var.cbr_rules[count.index].rule_contexts
  resources = [{
    attributes = [
      {
        name     = "accountId"
        value    = var.cbr_rules[count.index].account_id
        operator = "stringEquals"
      },
      {
        name     = "serviceInstance"
        value    = local.cluster_id
        operator = "stringEquals"
      },
      {
        name     = "serviceName"
        value    = "containers-kubernetes"
        operator = "stringEquals"
      }
    ],
  }]
  operations = var.cbr_rules[count.index].operations == null ? local.default_operations : var.cbr_rules[count.index].operations
}

##############################################################
# Ingress Secrets Manager Integration
##############################################################

module "existing_secrets_manager_instance_parser" {
  count   = var.enable_secrets_manager_integration ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_secrets_manager_instance_crn
}

resource "ibm_iam_authorization_policy" "ocp_secrets_manager_iam_auth_policy" {
  count                       = var.enable_secrets_manager_integration && !var.skip_ocp_secrets_manager_iam_auth_policy ? 1 : 0
  depends_on                  = [ibm_container_vpc_cluster.cluster, ibm_container_vpc_cluster.autoscaling_cluster, ibm_container_vpc_cluster.cluster_with_upgrade, ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade, module.worker_pools]
  source_service_name         = "containers-kubernetes"
  source_resource_instance_id = local.cluster_id
  target_service_name         = "secrets-manager"
  target_resource_instance_id = module.existing_secrets_manager_instance_parser[0].service_instance
  roles                       = ["Manager"]
}

resource "time_sleep" "wait_for_auth_policy" {
  count           = var.enable_secrets_manager_integration ? 1 : 0
  depends_on      = [ibm_iam_authorization_policy.ocp_secrets_manager_iam_auth_policy[0]]
  create_duration = "30s"
}


resource "ibm_container_ingress_instance" "instance" {
  count           = var.enable_secrets_manager_integration ? 1 : 0
  depends_on      = [time_sleep.wait_for_auth_policy]
  cluster         = var.cluster_name
  instance_crn    = var.existing_secrets_manager_instance_crn
  is_default      = true
  secret_group_id = var.secrets_manager_secret_group_id
  lifecycle {
    precondition {
      condition     = var.enable_secrets_manager_integration ? var.existing_secrets_manager_instance_crn != null : true
      error_message = "'existing_secrets_manager_instance_crn' should be  provided if setting 'enable_secrets_manager_integration' to true."
    }
  }
}


check "check_cluster_state" {

  data "ibm_container_vpc_cluster" "cluster_state" {

    depends_on = [ibm_container_vpc_cluster.cluster, ibm_container_vpc_cluster.cluster_with_upgrade, ibm_container_vpc_cluster.autoscaling_cluster, ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade, module.worker_pools, null_resource.confirm_network_healthy]
    name = var.cluster_name
    resource_group_id = var.resource_group_id
  }

  assert {
   condition     = data.ibm_container_vpc_cluster.cluster_state.state == "normal"
   error_message = "Cluster is not in normal state, currently it is in ${data.ibm_container_vpc_cluster.cluster_state.state} state"
 }

}