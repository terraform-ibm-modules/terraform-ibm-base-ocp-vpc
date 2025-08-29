##############################################################################
# Outputs
##############################################################################

output "ocp_version" {
  description = "OpenShift version of the cluster"
  value       = tonumber(data.external.get_ocp_cluster_version.result["ocp_version"])
}
