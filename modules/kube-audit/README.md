# Kubernetes API server audit logs

To monitor user-initiated, Kubernetes administrative activity made within your cluster, you can collect and forward audit events that are passed through your Kubernetes API server to IBM Cloud Logs or an external server.

This sub-module helps you to create a Kubernetes audit system by using the provided image and deployment in your existing cluster. [Learn more](https://cloud.ibm.com/docs/openshift?topic=openshift-health-audit)

**Important**: The sub-module uses the `icr.io/ibm/ibmcloud-kube-audit-to-ibm-cloud-logs` image to forward logs to IBM Cloud Logs. This image is for demonstration purposes only. For a production solution, configure and maintain your own log forwarding image.

### Usage

```hcl
# ############################################################################
# Init cluster config for helm
# ############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  # update this value with the Id of the cluster where these agents will be provisioned
  cluster_name_id = "cluster_id"
}

# ############################################################################
# Config providers
# ############################################################################

provider "ibm" {
  # update this value with your IBM Cloud API key value
  ibmcloud_api_key = "XXXXXXXXXXXXXXXXX" #pragma: allowlist secret
}

provider "helm" {
  kubernetes {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
  }
}

provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.cluster_config.host
  token                  = data.ibm_container_cluster_config.cluster_config.token
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
}

module "kube_audit" {
  source                    = "terraform-ibm-modules/terraform-ibm-base-ocp-vpc/ibm//modules/kube-audit"
  version                   = "X.X.X" # Replace "X.X.X" with a release version to lock into a specific release
  cluster_id                = "cluster_id"
  cluster_resource_group_id = "resource group id"
  region                    = "us-south"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.0, <4.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.78.2, <2.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1, < 4.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1, < 1.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.kube_audit](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.set_audit_log_policy](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.set_audit_webhook](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [time_sleep.wait_for_kube_audit](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_cluster) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audit_deployment_name"></a> [audit\_deployment\_name](#input\_audit\_deployment\_name) | The name of log collection deployment and service. | `string` | `"ibmcloud-kube-audit"` | no |
| <a name="input_audit_log_policy"></a> [audit\_log\_policy](#input\_audit\_log\_policy) | Specify the amount of information that is logged to the API server audit logs by choosing the audit log policy profile to use. Supported values are `default` and `WriteRequestBodies`. | `string` | `"default"` | no |
| <a name="input_audit_namespace"></a> [audit\_namespace](#input\_audit\_namespace) | The name of the namespace where log collection service and a deployment will be created. | `string` | `"ibm-kube-audit"` | no |
| <a name="input_audit_webhook_listener_image"></a> [audit\_webhook\_listener\_image](#input\_audit\_webhook\_listener\_image) | The audit webhook listener image reference in the format of `[registry-url]/[namespace]/[image]`.The sub-module uses the `icr.io/ibm/ibmcloud-kube-audit-to-ibm-cloud-logs` image to forward logs to IBM Cloud Logs. This image is for demonstration purposes only. For a production solution, configure and maintain your own log forwarding image. | `string` | `"icr.io/ibm/ibmcloud-kube-audit-to-ibm-cloud-logs"` | no |
| <a name="input_audit_webhook_listener_image_tag_digest"></a> [audit\_webhook\_listener\_image\_tag\_digest](#input\_audit\_webhook\_listener\_image\_tag\_digest) | The tag or digest for the audit webhook listener image to deploy. If changing the value, ensure it is compatible with `audit_webhook_listener_image`. | `string` | `"b119cab4729c4f92213a7a125d73adea14916a75@sha256:5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef"` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the cluster to deploy the log collection service in. | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | The resource group ID of the cluster. | `string` | n/a | yes |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud api key to generate an IAM token. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where the cluster is provisioned. | `string` | n/a | yes |
| <a name="input_use_private_endpoint"></a> [use\_private\_endpoint](#input\_use\_private\_endpoint) | Set this to true to force all api calls to use the IBM Cloud private endpoints. | `bool` | `false` | no |
| <a name="input_wait_till"></a> [wait\_till](#input\_wait\_till) | To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal` | `string` | `"IngressReady"` | no |
| <a name="input_wait_till_timeout"></a> [wait\_till\_timeout](#input\_wait\_till\_timeout) | Timeout for wait\_till in minutes. | `number` | `90` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
