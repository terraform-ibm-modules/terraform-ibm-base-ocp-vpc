##############################################################################
# Create a VPC with single zone and public gateway
##############################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "manual"
  tags                      = var.resource_tags
  access_tags               = var.access_tags
}

resource "ibm_is_vpc_address_prefix" "subnet_prefix" {
  name = "${var.prefix}-z-1"
  zone = "${var.region}-1"
  vpc  = ibm_is_vpc.vpc.id
  cidr = "10.10.10.0/24"
}

resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet" {
  name            = "${var.prefix}-subnet-1"
  vpc             = ibm_is_vpc.vpc.id
  resource_group  = module.resource_group.resource_group_id
  zone            = "${var.region}-1"
  ipv4_cidr_block = ibm_is_vpc_address_prefix.subnet_prefix.cidr
  network_acl     = ibm_is_network_acl.singlezone_acl.id
  public_gateway  = ibm_is_public_gateway.gateway.id
}

##############################################################################
# Define network ACLs based on public endpoints
##############################################################################

resource "ibm_is_network_acl" "singlezone_acl" {
  name           = "${var.prefix}-acl"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  access_tags    = var.access_tags
  rules {
    name        = "ibmflow-iaas-inbound"
    action      = "allow"
    source      = "161.26.0.0/16"
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
  rules {
    name        = "ibmflow-iaas-outbound"
    action      = "allow"
    destination = "161.26.0.0/16"
    source      = "0.0.0.0/0"
    direction   = "outbound"
  }
  rules {
    name        = "ibmflow-paas-inbound"
    action      = "allow"
    source      = "166.8.0.0/14"
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
  rules {
    name        = "ibmflow-paas-outbound"
    action      = "allow"
    destination = "166.8.0.0/14"
    source      = "0.0.0.0/0"
    direction   = "outbound"
  }
  rules {
    name        = "vpc-internal-ibound-allow"
    action      = "allow"
    source      = ibm_is_vpc_address_prefix.subnet_prefix.cidr
    destination = ibm_is_vpc_address_prefix.subnet_prefix.cidr
    direction   = "inbound"
  }
  rules {
    name        = "vpc-internal-outbound-allow"
    action      = "allow"
    source      = ibm_is_vpc_address_prefix.subnet_prefix.cidr
    destination = ibm_is_vpc_address_prefix.subnet_prefix.cidr
    direction   = "outbound"
  }
  rules {
    name      = "allow-all-443-inbound"
    action    = "allow"
    direction = "inbound"
    tcp {
      port_min = 443
      port_max = 443
    }
    destination = "0.0.0.0/0"
    source      = "0.0.0.0/0"
  }
  rules {
    name      = "allow-all-80-inbound"
    action    = "allow"
    direction = "inbound"
    tcp {
      port_min = 80
      port_max = 80
    }
    destination = "0.0.0.0/0"
    source      = "0.0.0.0/0"
  }
  rules {
    name      = "allow-all-ephemeral-inbound"
    action    = "allow"
    direction = "inbound"
    tcp {
      port_min = 30000
      port_max = 65535
    }
    destination = "0.0.0.0/0"
    source      = "0.0.0.0/0"
  }
  rules {
    name      = "allow-all-443-outbound"
    action    = "allow"
    direction = "outbound"
    tcp {
      source_port_min = 443
      source_port_max = 443
    }
    destination = "0.0.0.0/0"
    source      = "0.0.0.0/0"
  }
  rules {
    name      = "allow-all-80-outbound"
    action    = "allow"
    direction = "outbound"
    tcp {
      source_port_min = 80
      source_port_max = 80
    }
    destination = "0.0.0.0/0"
    source      = "0.0.0.0/0"
  }
  rules {
    name      = "allow-all-ephemeral-outbound"
    action    = "allow"
    direction = "outbound"
    tcp {
      source_port_min = 30000
      source_port_max = 65535
    }
    destination = "0.0.0.0/0"
    source      = "0.0.0.0/0"
  }
  rules {
    name        = "ibmflow-deny-all-inbound"
    action      = "deny"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
  rules {
    name        = "ibmflow-deny-all-outbound"
    action      = "deny"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
}
