#############################################################################
# Provision Resource Group
#############################################################################
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.7"
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Provision VPC
#############################################################################

module "vpc" {
  source            = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version           = "8.10.4"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  name              = "vpc"
  prefix            = var.prefix
  tags              = var.resource_tags
  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ],
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ],
    zone-3 = [
      {
        name           = "subnet-c"
        cidr           = "10.30.10.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ]
  }
}

#############################################################################
# Provision COS
#############################################################################

module "cos" {
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "10.7.3"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  cos_tags               = var.resource_tags
  bucket_name            = "${var.prefix}-bucket"
  retention_enabled      = false
  kms_encryption_enabled = false
}
