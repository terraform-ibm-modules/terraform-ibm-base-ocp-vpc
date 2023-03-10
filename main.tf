##############################################################################
# base-ocp-vpc-module
# Deploy Openshift cluster in IBM Cloud on VPC Gen 2
##############################################################################

# Segregate pools, as we need default pool for cluster creation
locals {
  # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
  default_pool            = element([for pool in var.worker_pools : pool if pool.pool_name == "default"], 0)
  other_pools             = [for pool in var.worker_pools : pool if pool.pool_name != "default" && !var.ignore_worker_pool_size_changes]
  other_autoscaling_pools = [for pool in var.worker_pools : pool if pool.pool_name != "default" && var.ignore_worker_pool_size_changes]

  latest_kube_version = "${data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions[length(data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions) - 1]}_openshift"
  kube_version        = var.ocp_version == null || var.ocp_version == "latest" ? local.latest_kube_version : "${var.ocp_version}_openshift"

  cos_name         = var.use_existing_cos == true || (var.use_existing_cos == false && var.cos_name != null) ? var.cos_name : "${var.cluster_name}_cos"
  cos_location     = "global"
  cos_plan         = "standard"
  cos_instance_crn = var.use_existing_cos != false ? var.existing_cos_id : ibm_resource_instance.cos_instance[0].id

  # Validation approach based on https://stackoverflow.com/a/66682419
  validate_condition = var.use_existing_cos == true && var.existing_cos_id == null
  validate_msg       = "A value for 'existing_cos_id' variable must be passed when 'use_existing_cos = true'"
  # tflint-ignore: terraform_unused_declarations
  validate_check = regex("^${local.validate_msg}$", (!local.validate_condition ? local.validate_msg : ""))

  delete_timeout = "2h"
  create_timeout = "3h"
  update_timeout = "3h"

  cluster_id = var.ignore_worker_pool_size_changes ? ibm_container_vpc_cluster.autoscaling_cluster[0].id : ibm_container_vpc_cluster.cluster[0].id
}

# Lookup the current default kube version
data "ibm_container_cluster_versions" "cluster_versions" {}

resource "ibm_resource_instance" "cos_instance" {
  count = var.use_existing_cos ? 0 : 1

  name              = local.cos_name
  resource_group_id = var.resource_group_id
  service           = "cloud-object-storage"
  plan              = local.cos_plan
  location          = local.cos_location
}

##############################################################################
# Create a OCP Cluster
##############################################################################

resource "ibm_container_vpc_cluster" "cluster" {
  depends_on                      = [null_resource.reset_api_key]
  count                           = var.ignore_worker_pool_size_changes ? 0 : 1
  name                            = var.cluster_name
  vpc_id                          = var.vpc_id
  tags                            = var.tags
  kube_version                    = local.kube_version
  flavor                          = local.default_pool.machine_type
  entitlement                     = var.ocp_entitlement
  cos_instance_crn                = local.cos_instance_crn
  worker_count                    = local.default_pool.workers_per_zone
  resource_group_id               = var.resource_group_id
  wait_till                       = var.cluster_ready_when
  force_delete_storage            = var.force_delete_storage
  disable_public_service_endpoint = var.disable_public_endpoint
  worker_labels                   = local.default_pool.labels

  lifecycle {
    ignore_changes = [kube_version]
  }

  # default workers are mapped to the subnets that are "private"
  dynamic "zones" {
    for_each = var.vpc_subnets[local.default_pool.subnet_prefix]
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
  count                           = var.ignore_worker_pool_size_changes ? 1 : 0
  name                            = var.cluster_name
  vpc_id                          = var.vpc_id
  tags                            = var.tags
  kube_version                    = local.kube_version
  flavor                          = local.default_pool.machine_type
  entitlement                     = var.ocp_entitlement
  cos_instance_crn                = local.cos_instance_crn
  worker_count                    = local.default_pool.workers_per_zone
  resource_group_id               = var.resource_group_id
  wait_till                       = var.cluster_ready_when
  force_delete_storage            = var.force_delete_storage
  disable_public_service_endpoint = var.disable_public_endpoint
  worker_labels                   = local.default_pool.labels

  lifecycle {
    ignore_changes = [worker_count, kube_version]
  }

  # default workers are mapped to the subnets that are "private"
  dynamic "zones" {
    for_each = var.vpc_subnets[local.default_pool.subnet_prefix]
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
    }
  }

  timeouts {
    # Extend create, update and delete timeout to static values.
    delete = local.delete_timeout
    create = local.create_timeout
    update = local.update_timeout
  }
}

# Cluster provisioning will automatically create an IAM API key called "containers-kubernetes-key" if one does not exist
# for the given region and resource group. The API key is used to access several services, such as the IBM Cloud classic
# infrastructure portfolio, and is required to manage the cluster. Immediately after the IAM API key is created and
# added to the new resource group, it is replicated across IAM Cloudant instances. There is a small period of time from
# when the IAM API key is initially created and when it is fully replicated across Cloudant instances where the API key
# does not work because it is not fully replicated, so commands that require the API key may fail with 404.
#
# WORKAROUND:
# Run a script that checks if an IAM API key already exists for the given region and resource group, and if it does not,
# run the ibmcloud ks api-key reset command to create one. The script will then pause for some time to allow any IAM
# Cloudant replication to occur. By doing this, it means the cluster provisioning process will not attempt to create a
# new key, and simply use the key created by this script. So hence should not face 404s anymore.
# The IKS team are tracking internally https://github.ibm.com/alchemy-containers/armada-ironsides/issues/5023

resource "null_resource" "reset_api_key" {
  provisioner "local-exec" {
    command     = "${path.module}/scripts/reset_iks_api_key.sh ${var.region} ${var.resource_group_id}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
    }
  }
}

##############################################################################
# Access cluster to kick off RBAC synchronisation
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = local.cluster_id
  config_dir        = "${path.module}/kubeconfig"
  resource_group_id = var.resource_group_id
}

##############################################################################
# Worker Pools
##############################################################################

resource "ibm_container_vpc_worker_pool" "pool" {
  for_each          = { for pool in local.other_pools : pool.pool_name => pool }
  vpc_id            = var.vpc_id
  resource_group_id = var.resource_group_id
  cluster           = local.cluster_id
  worker_pool_name  = each.value.pool_name
  flavor            = each.value.machine_type
  worker_count      = each.value.workers_per_zone
  labels            = each.value.labels

  dynamic "zones" {
    for_each = var.vpc_subnets[each.value.subnet_prefix]
    content {
      subnet_id = zones.value.id
      name      = zones.value.zone
    }
  }

  # Apply taints to worker pools i.e. other_pools

  dynamic "taints" {
    for_each = var.worker_pools_taints == null ? [] : concat(var.worker_pools_taints["all"], var.worker_pools_taints[each.value["pool_name"]])
    content {
      effect = taints.value.effect
      key    = taints.value.key
      value  = taints.value.value
    }
  }

}

# copy of the pool resource above which ignores changes to the worker pool for use in autoscaling scenarios
resource "ibm_container_vpc_worker_pool" "autoscaling_pool" {
  for_each          = { for pool in local.other_autoscaling_pools : pool.pool_name => pool }
  vpc_id            = var.vpc_id
  resource_group_id = var.resource_group_id
  cluster           = local.cluster_id
  worker_pool_name  = each.value.pool_name
  flavor            = each.value.machine_type
  worker_count      = each.value.workers_per_zone
  labels            = each.value.labels

  lifecycle {
    ignore_changes = [worker_count]
  }

  dynamic "zones" {
    for_each = var.vpc_subnets[each.value.subnet_prefix]
    content {
      subnet_id = zones.value.id
      name      = zones.value.zone
    }
  }

  # Apply taints to worker pools i.e. other_pools

  dynamic "taints" {
    for_each = var.worker_pools_taints == null ? [] : concat(var.worker_pools_taints["all"], var.worker_pools_taints[each.value["pool_name"]])
    content {
      effect = taints.value.effect
      key    = taints.value.key
      value  = taints.value.value
    }
  }

}

##############################################################################
# Confirm network healthy by ensuring master can communicate with all workers.
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

  depends_on = [ibm_container_vpc_worker_pool.pool, ibm_container_vpc_worker_pool.autoscaling_pool]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm_network_healthy.sh"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
