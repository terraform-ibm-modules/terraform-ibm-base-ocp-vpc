terraform {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=v8.9.2"
}

dependency "resource_group" {
  config_path = "../resource_group"
}

locals {
  prefix = "abcd"
}

inputs = {
  name              = "vpc"
  prefix            = local.prefix
  region            = "us-south"
  resource_group_id = dependency.resource_group.outputs.resource_group_id

  subnets = {
    "zone-1" = [
      {
        name           = "${local.prefix}subnet"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "${local.prefix}acl"
      }
    ]
  }

  use_public_gateways = {
    "zone-1" = true
    "zone-2" = false
    "zone-3" = false
  }

  network_acls = [
    {
      name                         = "${local.prefix}acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules = [
        {
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
  ]
}
