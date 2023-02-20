##############################################################################
# Outputs
##############################################################################

output "cluster_vpc_subnets" {
  value       = local.cluster_vpc_subnets
  description = "List of cluster vpc subnets"
}
### FOr validation
output "cluster_zones" {
  value       = local.cluster_zones
  description = "List of cluster zones"
}

output "subnet_ids" {
  value = module.vpc.subnet_ids
}

output "subnet_detail_list" {
  value = module.vpc.subnet_detail_list
}

output "subnet_zone_list" {
  value = module.vpc.subnet_zone_list
}
output "public_gateways" {
  value = module.vpc.public_gateways
}

output "vpc_name" {
  value = module.vpc.vpc_name
}

output "network_acls" {
  value = module.vpc.network_acls
}

##############################################################################