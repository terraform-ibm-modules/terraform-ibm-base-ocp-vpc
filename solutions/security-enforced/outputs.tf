########################################################################################################################
# Outputs
########################################################################################################################

output "cluster_name" {
  value       = module.base_ocp_vpc.cluster_name
  description = "The name of the provisioned OpenShift cluster."
}

output "cluster_id" {
  value       = module.base_ocp_vpc.cluster_id
  description = "The unique identifier assigned to the provisioned OpenShift cluster."
}

output "cluster_crn" {
  description = "The Cloud Resource Name (CRN) of the provisioned OpenShift cluster."
  value       = module.base_ocp_vpc.cluster_crn
}

output "workerpools" {
  description = "A list of worker pools associated with the provisioned cluster"
  value       = module.base_ocp_vpc.workerpools
}

output "ocp_version" {
  description = "The version of OpenShift running on the provisioned cluster."
  value       = module.base_ocp_vpc.ocp_version
}

output "cos_crn" {
  description = "The Cloud Resource Name (CRN) of the Object Storage instance associated with the cluster."
  value       = module.base_ocp_vpc.cos_crn
}

output "vpc_id" {
  description = "The ID of the Virtual Private Cloud (VPC) in which the cluster is deployed."
  value       = module.base_ocp_vpc.vpc_id
}

output "region" {
  description = "The IBM Cloud region where the cluster is deployed."
  value       = module.base_ocp_vpc.region
}

output "resource_group_id" {
  description = "The ID of the resource group where the cluster is deployed."
  value       = module.base_ocp_vpc.resource_group_id
}

output "ingress_hostname" {
  description = "The hostname assigned to the Cluster's Ingress subdomain for external access."
  value       = module.base_ocp_vpc.ingress_hostname
}

output "private_service_endpoint_url" {
  description = "The Private service endpoint URL for accessing the cluster over a private network."
  value       = module.base_ocp_vpc.private_service_endpoint_url
}

output "public_service_endpoint_url" {
  description = "The public service endpoint URL for accessing the cluster over the internet."
  value       = module.base_ocp_vpc.public_service_endpoint_url
}

output "master_url" {
  description = "The API endpoint URL for the Kubernetes master node of the cluster."
  value       = module.base_ocp_vpc.master_url
}

output "vpe_url" {
  description = "The Virtual Private Endpoint (VPE) URL used for private network access to the cluster."
  value       = module.base_ocp_vpc.vpe_url
}

output "kms_config" {
  description = "Configuration details for Key Management Service (KMS) used for encryption in the cluster."
  value       = module.base_ocp_vpc.kms_config
}

output "operating_system" {
  description = "The operating system used by the worker nodes in the default worker pool."
  value       = module.base_ocp_vpc.operating_system
}

output "master_status" {
  description = "The current status of the Kubernetes master node in the cluster."
  value       = module.base_ocp_vpc.master_status
}

output "master_vpe" {
  description = "Details of the master, or default Virtual Private Endpoint (VPE). For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway"
  value       = module.base_ocp_vpc.master_vpe
}

output "api_vpe" {
  description = "Details of the API Virtual Private Endpoint (VPE), if it exists. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway"
  value       = module.base_ocp_vpc.api_vpe
}

output "registry_vpe" {
  description = "Details of the registry Virtual Private Endpoint (VPE), if it exists. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway"
  value       = module.base_ocp_vpc.registry_vpe
}
