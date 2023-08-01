###############################################################################
# Resource Group
###############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.6"
  # if an existing resource group is not set (i.e. null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Create a VPC with single subnet and zone, and public gateway
# NOTE: this is a very simple VPC/Subnet configuration for example purposes only,
# that will allow all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets
# and zones for resiliency, and ACLs/Security Groups for network security.
##############################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.id
}

###############################################################################
# Base OCP
###############################################################################
locals {
  addons = {
    "cluster-autoscaler" = "1.0.8"
  }

  cluster_vpc_subnets = {
    default = [
      {
        id         = ibm_is_subnet.subnet_zone_1.id
        cidr_block = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_1.zone
      }
    ]
  }

  sz_pool = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
    },
    {
      subnet_prefix     = "default"
      pool_name         = "logging"
      machine_type      = "bx2.4x16"
      workers_per_zone  = 2
      minSize           = 1
      maxSize           = 6
      enableAutoscaling = true
    },
    {
      subnet_prefix     = "default"
      pool_name         = "sample"
      machine_type      = "bx2.4x16"
      workers_per_zone  = 4
      minSize           = 1
      maxSize           = 6
      enableAutoscaling = true
    }
  ]
}

module "ocp_base" {
  source               = "../.."
  cluster_name         = var.prefix
  ibmcloud_api_key     = var.ibmcloud_api_key
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = ibm_is_vpc.vpc.id
  vpc_subnets          = local.cluster_vpc_subnets
  ocp_version          = var.ocp_version
  tags                 = var.resource_tags
  worker_pools         = local.sz_pool
  addons               = local.addons
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_base.cluster_id
  resource_group_id = module.ocp_base.resource_group_id
  config_dir        = "${path.module}/../../kubeconfig"
}

##############################################################################
