terraform {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc.git?ref=v3.73.5"
}

include {
  path = find_in_parent_folders()
}

dependency "resource_group" {
  config_path = "../resource_group"
}

dependency "vpc" {
  config_path = "../vpc"
}

locals {
  prefix = "abcd"
}

inputs = {
  cluster_name = local.prefix

  region              = "us-south"
  resource_group_id   = dependency.resource_group.outputs.resource_group_id

  vpc_id              = dependency.vpc.outputs.vpc_id
  vpc_subnets         = dependency.vpc.outputs.subnet_detail_map

  force_delete_storage = true

  worker_pools = [
    {
      subnet_prefix    = "zone-1"     
      pool_name        = "default"
      machine_type     = "bx2.8x32"
      operating_system = "RHCOS"
      workers_per_zone = 2
    }
  ]
  enable_addons = false
  ocp_version     = null
  ocp_entitlement = null
  resource_tags   = []
  access_tags     = []

  disable_outbound_traffic_protection = true
}
