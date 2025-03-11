 module "ocp_base" {
  
  source                                = "terraform-ibm-modules/base-ocp-vpc/ibm"
  cluster_name                          = var.cluster_name
  resource_group_id                     = var.resource_group_id
  region                                = var.region
  ocp_version                           = var.ocp_version
  ocp_entitlement                       = var.ocp_entitlement
  vpc_id                                = var.vpc_id
  vpc_subnets                           = var.vpc_subnets
  worker_pools                          = var.worker_pools
  disable_outbound_traffic_protection   = true 
  access_tags                           = var.access_tags   
  addons = {
     "openshift-ai"       = "416"
  } 
  
}

