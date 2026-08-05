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
  valid_versions_list = data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions
  valid_ocp_versions  = [for version in local.valid_versions_list : regex("^([0-9]+\\.[0-9]+)", version)[0]]

  cos_name = var.use_existing_cos == true || (var.use_existing_cos == false && var.cos_name != null) ? var.cos_name : "${var.cluster_name}_cos"
  cos_plan = "standard"
  # if not enable_registry_storage then set cos to 'null', otherwise use existing or new CRN
  cos_instance_crn = var.enable_registry_storage == true ? (var.use_existing_cos != false ? var.existing_cos_id : module.cos_instance[0].cos_instance_id) : null

  # Cluster network plugin setting is only available for Red Hat OpenShift VPC clusters with version >= 4.20 and RHCOS operating system
  network_plugin = tonumber(regex("^([0-9]+\\.[0-9]+)", local.ocp_version)[0]) > 4.19 && local.default_pool.operating_system == local.os_rhcos ? var.network_plugin : null

  binaries_path = "/tmp"
}

########################################################################################################################
# Get OCP addon versions
########################################################################################################################

data "ibm_iam_auth_token" "tokendata" {}

data "external" "ocp_addon_versions" {
  program = ["bash", "${path.module}/scripts/get_ocp_addon_versions.sh"]
  query = {
    IAM_TOKEN = sensitive(data.ibm_iam_auth_token.tokendata.iam_access_token)
    REGION    = var.region
  }
}

# Local block to decode the json strings returned by the external data source
locals {
  ocp_all_addon_versions = {
    for addon, value in data.external.ocp_addon_versions.result :
    addon => jsondecode(value)
  }
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
  valid_rhel_worker_pools = tonumber(local.ocp_version_num) < 4.18 ? local.default_pool.operating_system == local.os_rhcos || (contains([local.os_rhel, local.os_rhel9], local.default_pool.operating_system) && alltrue(local.rhel_check_for_all_standalone_pools)) ? true : tobool("Choosing RHEL for the default worker pool will limit all additional worker pools to RHEL.") : true

  # Validate if RHCOS is used as operating system for the cluster then the default worker pool must be created with RHCOS
  rhcos_check = contains([local.os_rhel, local.os_rhel9], local.default_pool.operating_system) || (local.default_pool.operating_system == local.os_rhcos && local.default_pool.operating_system == local.os_rhcos)

  # tflint-ignore: terraform_unused_declarations
  default_wp_validation = local.rhcos_check ? true : tobool("If RHCOS is used with this cluster, the default worker pool should be created with RHCOS.")
}


# Lookup the current default kube version
data "ibm_container_cluster_versions" "cluster_versions" {}

module "cos_instance" {
  count = var.enable_registry_storage && !var.use_existing_cos ? 1 : 0

  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "10.17.3"
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

# Check whether access tags are valid and exist in the account
data "ibm_iam_access_tag" "access_tags" {
  for_each = length(var.access_tags) != 0 ? toset(var.access_tags) : [] # Force dependency on data source validation to ensure access_tags exist and are valid before use.
  name     = each.value
}

resource "ibm_resource_tag" "cos_access_tag" {
  depends_on  = [data.ibm_iam_access_tag.access_tags] # Force dependency on data source validation to ensure access_tags exist and are valid before use.
  count       = var.enable_registry_storage && !var.use_existing_cos && length(var.access_tags) > 0 ? 1 : 0
  resource_id = module.cos_instance[0].cos_instance_id
  tags        = var.access_tags
  tag_type    = "access"
}


module "cluster" {
  source = (
    "git::https://github.com/terraform-ibm-modules/terraform-ibm-base-cluster-vpc.git?ref=base-module"
  )

  cluster_type      = "openshift"
  cluster_name      = var.cluster_name
  resource_group_id = var.resource_group_id
  region            = var.region
  vpc_id            = var.vpc_id
  vpc_subnets       = var.vpc_subnets
  worker_pools      = var.worker_pools

  # Renamed from ocp_version.
  cluster_version = var.ocp_version

  # Renamed from enable_openshift_version_upgrade.
  enable_cluster_version_upgrade = var.enable_openshift_version_upgrade

  # Renamed from resource_tags.
  tags = var.resource_tags

  ocp_entitlement  = var.ocp_entitlement
  cos_instance_crn = local.cos_instance_crn

  allow_default_worker_pool_replacement = (
    var.allow_default_worker_pool_replacement
  )
  ignore_worker_pool_size_changes = var.ignore_worker_pool_size_changes
  worker_pools_taints             = var.worker_pools_taints

  attach_ibm_managed_security_group = (
    var.attach_ibm_managed_security_group
  )
  custom_security_group_ids         = var.custom_security_group_ids
  additional_lb_security_group_ids  = var.additional_lb_security_group_ids
  number_of_lbs                     = var.number_of_lbs
  additional_vpe_security_group_ids = var.additional_vpe_security_group_ids

  cluster_ready_when      = var.cluster_ready_when
  disable_public_endpoint = var.disable_public_endpoint
  disable_outbound_traffic_protection = (
    var.disable_outbound_traffic_protection
  )
  force_delete_storage       = var.force_delete_storage
  pod_subnet_cidr            = var.pod_subnet_cidr
  service_subnet_cidr        = var.service_subnet_cidr
  kms_config                 = var.kms_config
  image_security_enforcement = var.image_security_enforcement
  network_plugin             = local.network_plugin

  access_tags                  = var.access_tags
  cluster_config_endpoint_type = var.cluster_config_endpoint_type

  verify_worker_network_readiness = (
    var.verify_worker_network_readiness
  )
  install_required_binaries = var.install_required_binaries

  addons                    = var.addons
  manage_all_addons         = var.manage_all_addons
  cluster_autoscaler_config = var.cluster_autoscaler_config

  cbr_rules = var.cbr_rules

  enable_secrets_manager_integration = (
    var.enable_secrets_manager_integration
  )
  existing_secrets_manager_instance_crn = (
    var.existing_secrets_manager_instance_crn
  )
  secrets_manager_secret_group_id = (
    var.secrets_manager_secret_group_id
  )
  skip_secrets_manager_iam_auth_policy = (
    var.skip_ocp_secrets_manager_iam_auth_policy
  )

  cluster_delete_timeout = var.cluster_delete_timeout
  cluster_create_timeout = var.cluster_create_timeout
  cluster_update_timeout = var.cluster_update_timeout
}


##############################################################################
# Enable or Disable OCP Console Patch
##############################################################################
resource "terraform_data" "ocp_console_management" {
  count      = var.enable_ocp_console != null ? 1 : 0
  depends_on = [module.cluster]
  triggers_replace = {
    enable_ocp_console = var.enable_ocp_console
  }
  provisioner "local-exec" {
    command     = "${path.module}/scripts/enable_disable_ocp_console.sh ${local.binaries_path}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG         = module.cluster.kubeconfig_path
      ENABLE_OCP_CONSOLE = var.enable_ocp_console
    }
  }
}

moved {
  from = terraform_data.install_required_binaries[0]
  to   = module.cluster.terraform_data.install_required_binaries[0]
}
moved {
  from = ibm_container_vpc_cluster.cluster[0]
  to   = module.cluster.ibm_container_vpc_cluster.cluster[0]
}

moved {
  from = ibm_container_vpc_cluster.cluster_with_upgrade[0]
  to   = module.cluster.ibm_container_vpc_cluster.cluster_with_upgrade[0]
}

moved {
  from = ibm_container_vpc_cluster.autoscaling_cluster[0]
  to   = module.cluster.ibm_container_vpc_cluster.autoscaling_cluster[0]
}

moved {
  from = ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade[0]
  to   = module.cluster.ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade[0]
}

moved {
  from = ibm_resource_tag.cluster_access_tag[0]
  to   = module.cluster.ibm_resource_tag.cluster_access_tag[0]
}

moved {
  from = ibm_container_addons.ocp_addons[0]
  to   = module.cluster.ibm_container_addons.addons[0]
}

moved {
  from = kubernetes_config_map_v1_data.set_autoscaling[0]
  to   = module.cluster.kubernetes_config_map_v1_data.set_autoscaling[0]
}
moved {
  from = module.worker_pools
  to   = module.cluster.module.worker_pools
}

moved {
  from = module.attach_sg_to_lb[0]
  to   = module.cluster.module.attach_sg_to_lb[0]
}

moved {
  from = module.attach_sg_to_master_vpe[0]
  to   = module.cluster.module.attach_sg_to_master_vpe[0]
}

moved {
  from = module.attach_sg_to_api_vpe[0]
  to   = module.cluster.module.attach_sg_to_api_vpe[0]
}

moved {
  from = module.attach_sg_to_registry_vpe[0]
  to   = module.cluster.module.attach_sg_to_registry_vpe[0]
}

moved {
  from = module.cbr_rule[0]
  to   = module.cluster.module.cbr_rule[0]
}

moved {
  from = module.existing_secrets_manager_instance_parser[0]
  to   = module.cluster.module.existing_secrets_manager_instance_parser[0]
}

moved {
  from = ibm_iam_authorization_policy.ocp_secrets_manager_iam_auth_policy[0]
  to   = module.cluster.ibm_iam_authorization_policy.ocp_secrets_manager_iam_auth_policy[0]
}

moved {
  from = module.existing_secrets_manager_instance_parser[0]
  to   = module.cluster.module.existing_secrets_manager_instance_parser[0]
}

moved {
  from = time_sleep.wait_for_auth_policy[0]
  to   = module.cluster.time_sleep.wait_for_auth_policy[0]
}

moved {
  from = ibm_container_ingress_instance.instance[0]
  to   = module.cluster.ibm_container_ingress_instance.instance[0]
}
