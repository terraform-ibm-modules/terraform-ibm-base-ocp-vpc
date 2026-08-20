########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.6.1"
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Provision VPC
#############################################################################
locals {
  prefix = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  network_acl = {
    name                         = "${local.prefix}acl"
    add_ibm_cloud_internal_rules = true
    add_vpc_connectivity_rules   = true
    prepend_ibm_rules            = true
    rules = [{
      name        = "${local.prefix}inbound"
      action      = "allow"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      },
      {
        name        = "${local.prefix}outbound"
        action      = "allow"
        source      = "0.0.0.0/0"
        destination = "0.0.0.0/0"
        direction   = "outbound"
      }
    ]
  }
}

module "vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "9.1.1"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  name              = "vpc"
  prefix            = var.prefix
  resource_tags     = var.resource_tags
  network_acls      = [local.network_acl]
  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "${local.prefix}acl"
      }
    ],
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = false
        acl_name       = "${local.prefix}acl"
      }
    ],
    zone-3 = [
      {
        name           = "subnet-c"
        cidr           = "10.30.10.0/24"
        public_gateway = false
        acl_name       = "${local.prefix}acl"
      }
    ]
  }
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################

locals {
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
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "mx3d.metal.64x512"
      workers_per_zone = 1
      operating_system = "RHCOS"
    }
  ]
}


module "ocp_base" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source            = "terraform-ibm-modules/base-ocp-vpc/ibm"
  # version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  resource_tags        = var.resource_tags
  cluster_name         = var.prefix
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = local.cluster_vpc_subnets
  ocp_version          = var.ocp_version
  worker_pools         = local.worker_pools
  access_tags          = var.access_tags
  network_plugin       = "OVNKubernetes"
  ocp_entitlement      = var.ocp_entitlement
  offering             = "openshift-vs"
  addons = {
    "openshift-data-foundation" = {
      version = "${var.ocp_version}.0"
      # The following parameters need to be added to enable ODF for virtualization.
      parameters_json = <<PARAMETERS_JSON
        {
            "odfDeploy":"true",
            "osdStorageClassName":"localblock",
            "autoDiscoverDevices": "true",
            "resourceProfile": "performance",
            "setDefaultStorageClassForVirtualization":"true"
        }
        PARAMETERS_JSON
    }
  }
  disable_outbound_traffic_protection = true # set as True to enable outbound traffic; required for accessing Operator Hub in the OpenShift console.
}
