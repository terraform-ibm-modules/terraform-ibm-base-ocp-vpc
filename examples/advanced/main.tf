########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.7"
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
  version                   = "5.5.16"
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
# Subnets across 3 zones
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
  worker_pool = [
    {
      subnet_prefix    = "zone-1"
      pool_name        = "workerpool"
      machine_type     = "bx2.4x16"
      operating_system = "REDHAT_8_64"
      workers_per_zone = 2
    }
  ]
}

module "ocp_base" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source            = "terraform-ibm-modules/base-ocp-vpc/ibm"
  # version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  cluster_name                     = var.prefix
  resource_group_id                = module.resource_group.resource_group_id
  region                           = var.region
  force_delete_storage             = true
  vpc_id                           = ibm_is_vpc.vpc.id
  vpc_subnets                      = local.cluster_vpc_subnets
  worker_pools                     = local.worker_pools
  ocp_version                      = var.ocp_version
  tags                             = var.resource_tags
  access_tags                      = var.access_tags
  worker_pools_taints              = local.worker_pools_taints
  ocp_entitlement                  = var.ocp_entitlement
  enable_openshift_version_upgrade = var.enable_openshift_version_upgrade
  # Enable if using worker autoscaling. Stops Terraform managing worker count.
  ignore_worker_pool_size_changes = true
  addons = {
    "cluster-autoscaler" = { version = "1.2.3" }
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

########################################################################################################################
# Worker Pool
########################################################################################################################

module "worker_pool" {
  source            = "../../modules/worker-pool"
  resource_group_id = module.resource_group.resource_group_id
  vpc_id            = ibm_is_vpc.vpc.id
  cluster_id        = module.ocp_base.cluster_id
  vpc_subnets       = local.cluster_vpc_subnets
  worker_pools      = local.worker_pool
}

########################################################################################################################
# Kube Audit
########################################################################################################################

module "kube_audit" {
  depends_on = [module.ocp_base] # Wait for the cluster to completely deploy.
  source     = "../../modules/kube-audit"
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source            = "terraform-ibm-modules/base-ocp-vpc/ibm//modules/kube-audit"
  # version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  cluster_id                = module.ocp_base.cluster_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  audit_log_policy          = "WriteRequestBodies"
  region                    = var.region
  ibmcloud_api_key          = var.ibmcloud_api_key
}


########################################################################################################################
# Observability (Instance + Agents)
########################################################################################################################

locals {
  logs_agent_namespace = "ibm-observe"
  logs_agent_name      = "logs-agent"
}

module "cloud_logs" {
  source            = "terraform-ibm-modules/cloud-logs/ibm"
  version           = "1.10.15"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  plan              = "standard"
  instance_name     = "${var.prefix}-cloud-logs"
}

module "trusted_profile" {
  source                      = "terraform-ibm-modules/trusted-profile/ibm"
  version                     = "3.2.17"
  trusted_profile_name        = "${var.prefix}-profile"
  trusted_profile_description = "Logs agent Trusted Profile"
  # As a `Sender`, you can send logs to your IBM Cloud Logs service instance - but not query or tail logs. This role is meant to be used by agents and routers sending logs.
  trusted_profile_policies = [{
    roles             = ["Sender"]
    unique_identifier = "${var.prefix}-profile-0"
    resources = [{
      service = "logs"
    }]
  }]
  # Set up fine-grained authorization for `logs-agent` running in ROKS cluster in `ibm-observe` namespace.
  trusted_profile_links = [{
    cr_type           = "ROKS_SA"
    unique_identifier = "${var.prefix}-profile"
    links = [{
      crn       = module.ocp_base.cluster_crn
      namespace = local.logs_agent_namespace
      name      = local.logs_agent_name
    }]
    }
  ]
}

module "logs_agents" {
  depends_on                    = [module.kube_audit]
  source                        = "terraform-ibm-modules/logs-agent/ibm"
  version                       = "1.16.2"
  cluster_id                    = module.ocp_base.cluster_id
  cluster_resource_group_id     = module.resource_group.resource_group_id
  logs_agent_trusted_profile_id = module.trusted_profile.trusted_profile.id
  logs_agent_namespace          = local.logs_agent_namespace
  logs_agent_name               = local.logs_agent_name
  cloud_logs_ingress_endpoint   = module.cloud_logs.ingress_private_endpoint
  cloud_logs_ingress_port       = 3443
  # example of how to add additional metadata to the logs agents
  logs_agent_additional_metadata = [{
    key   = "cluster_id"
    value = module.ocp_base.cluster_id
  }]
  # example of how to add only kube-audit log source path
  logs_agent_selected_log_source_paths = ["/var/log/audit/*.log"]
}
