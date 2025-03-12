 locals{
  allowed_ocp_version = ["4.16", "4.17", "4.18"]
  flavor_list=["bx2.16x64", "bx2.32x128", "bx2.48x192", "bx2.8x32", "cx2.16x32", "cx2.32x64", "cx2.48x96", "gx3.16x80.l4", "gx3.24x120.l40s", "gx3.32x160.2l4", "gx3.48x240.2l40s", "gx3.64x320.4l4", "gx3d.160x1792.8h100", "gx3d.160x1792.8h200", "mx2.16x128", "mx2.128x1024", "mx2.16x128.2000gb", "mx2.32x256", "mx2.48x384", "mx2.64x512", "mx2.8x64", "ox2.128x1024", "ox2.16x128", "ox2.32x256", "ox2.64x512", "ox2.8x64", "ox2.96x768" ]
  os_version = ["RHEL_9_64", "REDHAT_8_64", "RHCOS"]
 }
 
 
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

