# Financial Services Cloud Profile
## Note: OCP is not Financial Services Cloud Compliant
:exclamation: **Important:** Currently, OCP provisions a COS bucket, but you cannot use your own encryption keys. This will fail the requirement for Cloud Object Storage to be enabled with customer-managed encryption and Keep Your Own Key (KYOK).
Once the service supports this the profile will be updated. Until that time it is for educational purposes only.

This is a profile for IBM Cloud Red Hat OpenShift cluster on VPC Gen2 that meets FS Cloud requirements. This profile assumes you are deploying into an already compliant account.
It has been scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) and meets all applicable goals.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 1.6.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_fscloud"></a> [fscloud](#module\_fscloud) | ../.. | n/a |

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | A list of access tags to apply to the resources created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details | `list(string)` | `[]` | no |
| <a name="input_addons"></a> [addons](#input\_addons) | Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters, however you can explicitly specify it here if you wish to choose a later version than the default one). For full list of all supported add-ons and versions, see https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions | <pre>object({<br>    alb-oauth-proxy           = optional(string)<br>    debug-tool                = optional(string)<br>    image-key-synchronizer    = optional(string)<br>    istio                     = optional(string)<br>    openshift-data-foundation = optional(string)<br>    static-route              = optional(string)<br>    cluster-autoscaler        = optional(string)<br>    vpc-block-csi-driver      = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name that will be assigned to the provisioned cluster | `string` | n/a | yes |
| <a name="input_cluster_ready_when"></a> [cluster\_ready\_when](#input\_cluster\_ready\_when) | The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady | `string` | `"IngressReady"` | no |
| <a name="input_existing_cos_id"></a> [existing\_cos\_id](#input\_existing\_cos\_id) | The COS id of an already existing COS instance | `string` | n/a | yes |
| <a name="input_force_delete_storage"></a> [force\_delete\_storage](#input\_force\_delete\_storage) | Flag indicating whether or not to delete attached storage when destroying the cluster - Default: false | `bool` | `false` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | APIkey that's associated with the account to use | `string` | n/a | yes |
| <a name="input_ignore_worker_pool_size_changes"></a> [ignore\_worker\_pool\_size\_changes](#input\_ignore\_worker\_pool\_size\_changes) | Enable if using worker autoscaling. Stops Terraform managing worker count | `bool` | `false` | no |
| <a name="input_kms_config"></a> [kms\_config](#input\_kms\_config) | Use to attach a HPCS instance to the cluster. if account\_id is not provided, defaults to the account in use. | <pre>object({<br>    crk_id           = string<br>    instance_id      = string<br>    private_endpoint = optional(bool, true) # defaults to true<br>    account_id       = optional(string)     # To attach HPCS instance from another account<br>  })</pre> | n/a | yes |
| <a name="input_ocp_entitlement"></a> [ocp\_entitlement](#input\_ocp\_entitlement) | Value that is applied to the entitlements for OCP cluster provisioning | `string` | `"cloud_pak"` | no |
| <a name="input_ocp_version"></a> [ocp\_version](#input\_ocp\_version) | The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. Supports passing the string 'latest' (current latest available version) or 'default' (current IKS default recommended version). If no value is passed, it will default to 'default'. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where the cluster will be provisioned. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The Id of an existing IBM Cloud resource group where the cluster will be grouped. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Metadata labels describing this cluster deployment | `list(string)` | `[]` | no |
| <a name="input_verify_worker_network_readiness"></a> [verify\_worker\_network\_readiness](#input\_verify\_worker\_network\_readiness) | By setting this to true, a script will run kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, this should be set to false. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC instance where this cluster will be provisioned | `string` | n/a | yes |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | Metadata that describes the VPC's subnets. Obtain this information from the VPC where this cluster will be created | <pre>map(list(object({<br>    id         = string<br>    zone       = string<br>    cidr_block = string<br>  })))</pre> | n/a | yes |
| <a name="input_worker_pools"></a> [worker\_pools](#input\_worker\_pools) | List of worker pools | <pre>list(object({<br>    subnet_prefix     = string<br>    pool_name         = string<br>    machine_type      = string<br>    workers_per_zone  = number<br>    resource_group_id = optional(string)<br>    labels            = optional(map(string))<br>    boot_volume_encryption_kms_config = optional(object({<br>      crk             = string<br>      kms_instance_id = string<br>      kms_account_id  = optional(string)<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_worker_pools_taints"></a> [worker\_pools\_taints](#input\_worker\_pools\_taints) | Optional, Map of lists containing node taints by node-pool name | `map(list(object({ key = string, value = string, effect = string })))` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_crn"></a> [cluster\_crn](#output\_cluster\_crn) | CRN for the created cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of cluster created |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the created cluster |
| <a name="output_cos_crn"></a> [cos\_crn](#output\_cos\_crn) | CRN of the COS instance |
| <a name="output_ingress_hostname"></a> [ingress\_hostname](#output\_ingress\_hostname) | Ingress hostname |
| <a name="output_ocp_version"></a> [ocp\_version](#output\_ocp\_version) | Openshift Version of the cluster |
| <a name="output_private_service_endpoint_url"></a> [private\_service\_endpoint\_url](#output\_private\_service\_endpoint\_url) | Private service endpoint URL |
| <a name="output_region"></a> [region](#output\_region) | Region cluster is deployed in |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | Resource group ID the cluster is deployed in |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the clusters VPC |
| <a name="output_workerpools"></a> [workerpools](#output\_workerpools) | Worker pools created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
