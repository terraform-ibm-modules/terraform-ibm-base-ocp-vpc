# OpenShift Virtualization on OCP VPC cluster

This architecture help setting up OpenShift Virtualization on OCP VPC cluster. Also the outbound traffic is allowed, which is required for accessing the Operator Hub.

Prerequisites:
- A OCP VPC cluster.
- Outbound traffic protection disabled.

The following resources are provisioned by this example:

- Install `openshift-data-foundation` and `vpc-file-csi-driver` addons.
- Setup OperatorHub

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.17.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.75.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.35.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.3 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.12.1 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.operator](https://registry.terraform.io/providers/hashicorp/helm/2.17.0/docs/resources/release) | resource |
| [helm_release.subscription](https://registry.terraform.io/providers/hashicorp/helm/2.17.0/docs/resources/release) | resource |
| [ibm_container_addons.addons](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.75.1/docs/resources/container_addons) | resource |
| [kubernetes_config_map_v1_data.disable_default_storageclass](https://registry.terraform.io/providers/hashicorp/kubernetes/2.35.1/docs/resources/config_map_v1_data) | resource |
| [kubernetes_config_map_v1_data.set_vpc_file_default_storage_class](https://registry.terraform.io/providers/hashicorp/kubernetes/2.35.1/docs/resources/config_map_v1_data) | resource |
| [null_resource.config_map_status](https://registry.terraform.io/providers/hashicorp/null/3.2.3/docs/resources/resource) | resource |
| [null_resource.enable_catalog_source](https://registry.terraform.io/providers/hashicorp/null/3.2.3/docs/resources/resource) | resource |
| [null_resource.update_storage_profile](https://registry.terraform.io/providers/hashicorp/null/3.2.3/docs/resources/resource) | resource |
| [time_sleep.wait_for_default_storage](https://registry.terraform.io/providers/hashicorp/time/0.12.1/docs/resources/sleep) | resource |
| [time_sleep.wait_for_storage_profile](https://registry.terraform.io/providers/hashicorp/time/0.12.1/docs/resources/sleep) | resource |
| [time_sleep.wait_for_subscription](https://registry.terraform.io/providers/hashicorp/time/0.12.1/docs/resources/sleep) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.75.1/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.75.1/docs/data-sources/container_vpc_cluster) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify the type of endpoint to use to access the cluster configuration. Possible values: `default`, `private`, `vpe`, `link`. The `default` value uses the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the cluster to deploy the agents in. | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | The resource group ID of the cluster. | `string` | n/a | yes |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud API key. | `string` | n/a | yes |
| <a name="input_provider_visibility"></a> [provider\_visibility](#input\_provider\_visibility) | Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints). | `string` | `"public"` | no |
| <a name="input_provision_odf_addon"></a> [provision\_odf\_addon](#input\_provision\_odf\_addon) | Set this variable to true to install OpenShift Data Foundation addon in your existing cluster. | `bool` | `false` | no |
| <a name="input_provision_vpc_file_addon"></a> [provision\_vpc\_file\_addon](#input\_provision\_vpc\_file\_addon) | Set this variable to true to install File Storage for VPC addon in your existing cluster. | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | The region in which to provision all resources created by this solution. | `string` | `"us-south"` | no |
| <a name="input_vpc_file_default_storage_class"></a> [vpc\_file\_default\_storage\_class](#input\_vpc\_file\_default\_storage\_class) | The name of the VPC File storage class which will be set as the default storage class. | `string` | `"ibmc-vpc-file-metro-1000-iops"` | no |
| <a name="input_wait_till"></a> [wait\_till](#input\_wait\_till) | To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal` | `string` | `"Normal"` | no |
| <a name="input_wait_till_timeout"></a> [wait\_till\_timeout](#input\_wait\_till\_timeout) | Timeout for wait\_till in minutes. | `number` | `90` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
