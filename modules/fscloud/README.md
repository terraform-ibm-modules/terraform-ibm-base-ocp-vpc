# Financial Services Cloud Profile
## Note: OCP is not Financial Services Cloud Compliant
:exclamation: **Important:** Currently, OCP provisions a COS bucket, but you cannot use your own encryption keys. This will fail the requirement for Cloud Object Storage to be enabled with customer-managed encryption and Keep Your Own Key (KYOK).
Once the service supports this the profile will be updated. Until that time it is for educational purposes only.

This is a profile for IBM Cloud Red Hat OpenShift cluster on VPC Gen2 that meets FS Cloud requirements. This profile assumes you are deploying into an already compliant account.
It has been scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) and meets all applicable goals.


### Usage

```hcl
module "ocp_base_fscloud" {
  source               = "terraform-ibm-modules/terraform-ibm-base-ocp-vpc/ibm//modules/fscloud"
  version              = "X.X.X" # Replace "X.X.X" with a release version to lock into a specific release
  cluster_name         = "example-fs-cluster-name"
  resource_group_id    = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
  region               = "us-south"
  force_delete_storage = true
  vpc_id               = "79cxxxx-xxxx-xxxx-xxxx-xxxxxXX8667"
  # obtain the below values from the targeted VPC and adjust to the number of zones, subnets, subnet name, cidr_block, id, zone
  vpc_subnets          = {
    zone-1    = [
        {
            cidr_block = "192.168.32.0/22"
            id         = "0717-afc29fbb-0dbe-493a-a5b9-f3c5899cb8b9"
            zone       = "us-south-1"
        },
        {
            cidr_block = "192.168.36.0/22"
            id         = "0727-d65c1eda-9e38-4200-8452-cb8ff5bb3140"
            zone       = "us-south-2"
        },
        {
            cidr_block = "192.168.40.0/22"
            id         = "0737-9a823cd3-16bf-4ba4-a429-9e1fc7db74b8"
            zone       = "us-south-3"
        }
    ]
    zone-2 = [
        {
            cidr_block = "192.168.0.0/22"
            id         = "0717-846b9490-34ae-4a6c-8288-28112dca1ba3"
            zone       = "us-south-1"
        },
        {
            cidr_block = "192.168.4.0/22"
            id         = "0727-ef8db7f6-ffa5-4d8b-a317-4631741a45ee"
            zone       = "us-south-2"
        },
        {
            cidr_block = "192.168.8.0/22"
            id         = "0737-c9a6d871-d95b-4914-abf5-82c22f4161d1"
            zone       = "us-south-3"
        }
    ]
    zone-3 = [
        {
            cidr_block = "192.168.16.0/22"
            id         = "0717-d46e227c-89d4-4b02-9008-d03907a275b6"
            zone       = "us-south-1"
        },
        {
            cidr_block = "192.168.20.0/22"
            id         = "0727-93b1edcb-966c-4517-a7af-6ac63cd93adf"
            zone       = "us-south-2"
        },
        {
            cidr_block = "192.168.24.0/22"
            id         = "0737-807ec4f1-4d84-484e-b2f4-62dd5e431065"
            zone       = "us-south-3"
        }
    ]
  }
  worker_pools         = [
    {
      subnet_prefix    = "default"
      pool_name        = "default"
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      operating_system = "REDHAT_8_64"
    }
  ]
  import_default_worker_pool_on_create = false
  use_private_endpoint                 = true

}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.70.0, < 2.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.16.1, < 3.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1, < 4.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1, < 1.0.0 |

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
| <a name="input_additional_lb_security_group_ids"></a> [additional\_lb\_security\_group\_ids](#input\_additional\_lb\_security\_group\_ids) | Additional security groups to add to the load balancers associated with the cluster. Ensure that the number\_of\_lbs is set to the number of LBs associated with the cluster. This comes in addition to the IBM maintained security group. | `list(string)` | `[]` | no |
| <a name="input_additional_vpe_security_group_ids"></a> [additional\_vpe\_security\_group\_ids](#input\_additional\_vpe\_security\_group\_ids) | Additional security groups to add to all existing load balancers. This comes in addition to the IBM maintained security group. | <pre>object({<br/>    master   = optional(list(string), [])<br/>    registry = optional(list(string), [])<br/>    api      = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_addons"></a> [addons](#input\_addons) | Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters and 'ibm-storage-operator' is installed by default in OCP 4.15 and later, however you can explicitly specify it here if you wish to choose a later version than the default one). For full list of all supported add-ons and versions, see https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions | <pre>object({<br/>    debug-tool                = optional(string)<br/>    image-key-synchronizer    = optional(string)<br/>    openshift-data-foundation = optional(string)<br/>    vpc-file-csi-driver       = optional(string)<br/>    static-route              = optional(string)<br/>    cluster-autoscaler        = optional(string)<br/>    vpc-block-csi-driver      = optional(string)<br/>    ibm-storage-operator      = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_allow_default_worker_pool_replacement"></a> [allow\_default\_worker\_pool\_replacement](#input\_allow\_default\_worker\_pool\_replacement) | (Advanced users) Set to true to allow the module to recreate a default worker pool. Only use in the case where you are getting an error indicating that the default worker pool cannot be replaced on apply. Once the default worker pool is handled as a stand-alone ibm\_container\_vpc\_worker\_pool, if you wish to make any change to the default worker pool which requires the re-creation of the default pool set this variable to true. | `bool` | `false` | no |
| <a name="input_attach_ibm_managed_security_group"></a> [attach\_ibm\_managed\_security\_group](#input\_attach\_ibm\_managed\_security\_group) | Specify whether to attach the IBM-defined default security group (whose name is kube-<clusterid>) to all worker nodes. Only applicable if custom\_security\_group\_ids is set. | `bool` | `true` | no |
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | The list of context-based restriction rules to create. | <pre>list(object({<br/>    description = string<br/>    account_id  = string<br/>    rule_contexts = list(object({<br/>      attributes = optional(list(object({<br/>        name  = string<br/>        value = string<br/>    }))) }))<br/>    enforcement_mode = string<br/>    tags = optional(list(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/>    operations = optional(list(object({<br/>      api_types = list(object({<br/>        api_type_id = string<br/>      }))<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'private', 'vpe', 'link'. | `string` | `"private"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name that will be assigned to the provisioned cluster | `string` | n/a | yes |
| <a name="input_cluster_ready_when"></a> [cluster\_ready\_when](#input\_cluster\_ready\_when) | The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady | `string` | `"IngressReady"` | no |
| <a name="input_custom_security_group_ids"></a> [custom\_security\_group\_ids](#input\_custom\_security\_group\_ids) | Security groups to add to all worker nodes. This comes in addition to the IBM maintained security group if use\_ibm\_managed\_security\_group is set to true. If this variable is set, the default VPC security group is NOT assigned to the worker nodes. | `list(string)` | `null` | no |
| <a name="input_enable_ocp_console"></a> [enable\_ocp\_console](#input\_enable\_ocp\_console) | Flag to specify whether to enable or disable the OpenShift console. | `bool` | `true` | no |
| <a name="input_existing_cos_id"></a> [existing\_cos\_id](#input\_existing\_cos\_id) | The COS id of an already existing COS instance | `string` | n/a | yes |
| <a name="input_force_delete_storage"></a> [force\_delete\_storage](#input\_force\_delete\_storage) | Flag indicating whether or not to delete attached storage when destroying the cluster - Default: false | `bool` | `false` | no |
| <a name="input_ignore_worker_pool_size_changes"></a> [ignore\_worker\_pool\_size\_changes](#input\_ignore\_worker\_pool\_size\_changes) | Enable if using worker autoscaling. Stops Terraform managing worker count | `bool` | `false` | no |
| <a name="input_import_default_worker_pool_on_create"></a> [import\_default\_worker\_pool\_on\_create](#input\_import\_default\_worker\_pool\_on\_create) | (Advanced users) Whether to handle the default worker pool as a stand-alone ibm\_container\_vpc\_worker\_pool resource on cluster creation. Only set to false if you understand the implications of managing the default worker pool as part of the cluster resource. Set to true to import the default worker pool as a separate resource. Set to false to manage the default worker pool as part of the cluster resource. | `bool` | `true` | no |
| <a name="input_kms_config"></a> [kms\_config](#input\_kms\_config) | Use to attach a HPCS instance to the cluster. If account\_id is not provided, defaults to the account in use. | <pre>object({<br/>    crk_id           = string<br/>    instance_id      = string<br/>    private_endpoint = optional(bool, true) # defaults to true<br/>    account_id       = optional(string)     # To attach HPCS instance from another account<br/>    wait_for_apply   = optional(bool, true) # defaults to true so terraform will wait until the KMS is applied to the master, ready and deployed<br/>  })</pre> | n/a | yes |
| <a name="input_number_of_lbs"></a> [number\_of\_lbs](#input\_number\_of\_lbs) | The number of LBs to associated the additional\_lb\_security\_group\_names security group with. | `number` | `1` | no |
| <a name="input_ocp_entitlement"></a> [ocp\_entitlement](#input\_ocp\_entitlement) | Value that is applied to the entitlements for OCP cluster provisioning | `string` | `null` | no |
| <a name="input_ocp_version"></a> [ocp\_version](#input\_ocp\_version) | The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. Supports passing the string 'default' (current IKS default recommended version). If no value is passed, it will default to 'default'. | `string` | `null` | no |
| <a name="input_pod_subnet_cidr"></a> [pod\_subnet\_cidr](#input\_pod\_subnet\_cidr) | Specify a custom subnet CIDR to provide private IP addresses for pods. The subnet must have a CIDR of at least `/23` or larger. Default value is `172.30.0.0/16` when the variable is set to `null`. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where the cluster will be provisioned. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The Id of an existing IBM Cloud resource group where the cluster will be grouped. | `string` | n/a | yes |
| <a name="input_service_subnet_cidr"></a> [service\_subnet\_cidr](#input\_service\_subnet\_cidr) | Specify a custom subnet CIDR to provide private IP addresses for services. The subnet must be at least `/24` or larger. Default value is `172.21.0.0/16` when the variable is set to `null`. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Metadata labels describing this cluster deployment | `list(string)` | `[]` | no |
| <a name="input_use_private_endpoint"></a> [use\_private\_endpoint](#input\_use\_private\_endpoint) | Set this to true to force all api calls to use the IBM Cloud private endpoints. | `bool` | `false` | no |
| <a name="input_verify_worker_network_readiness"></a> [verify\_worker\_network\_readiness](#input\_verify\_worker\_network\_readiness) | By setting this to true, a script will run kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, this should be set to false. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC instance where this cluster will be provisioned | `string` | n/a | yes |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | Metadata that describes the VPC's subnets. Obtain this information from the VPC where this cluster will be created | <pre>map(list(object({<br/>    id         = string<br/>    zone       = string<br/>    cidr_block = string<br/>  })))</pre> | n/a | yes |
| <a name="input_worker_pools"></a> [worker\_pools](#input\_worker\_pools) | List of worker pools | <pre>list(object({<br/>    subnet_prefix = optional(string)<br/>    vpc_subnets = optional(list(object({<br/>      id         = string<br/>      zone       = string<br/>      cidr_block = string<br/>    })))<br/>    pool_name         = string<br/>    machine_type      = string<br/>    workers_per_zone  = number<br/>    resource_group_id = optional(string)<br/>    operating_system  = string<br/>    labels            = optional(map(string))<br/>    minSize           = optional(number)<br/>    secondary_storage = optional(string)<br/>    maxSize           = optional(number)<br/>    enableAutoscaling = optional(bool)<br/>    boot_volume_encryption_kms_config = optional(object({<br/>      crk             = string<br/>      kms_instance_id = string<br/>      kms_account_id  = optional(string)<br/>    }))<br/>    additional_security_group_ids = optional(list(string))<br/>  }))</pre> | n/a | yes |
| <a name="input_worker_pools_taints"></a> [worker\_pools\_taints](#input\_worker\_pools\_taints) | Optional, Map of lists containing node taints by node-pool name | `map(list(object({ key = string, value = string, effect = string })))` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_crn"></a> [cluster\_crn](#output\_cluster\_crn) | CRN for the created cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of cluster created |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the created cluster |
| <a name="output_cos_crn"></a> [cos\_crn](#output\_cos\_crn) | CRN of the COS instance |
| <a name="output_ingress_hostname"></a> [ingress\_hostname](#output\_ingress\_hostname) | The hostname that was assigned to your Ingress subdomain. |
| <a name="output_master_status"></a> [master\_status](#output\_master\_status) | The status of the Kubernetes master. |
| <a name="output_master_url"></a> [master\_url](#output\_master\_url) | The URL of the Kubernetes master. |
| <a name="output_ocp_version"></a> [ocp\_version](#output\_ocp\_version) | Openshift Version of the cluster |
| <a name="output_operating_system"></a> [operating\_system](#output\_operating\_system) | The operating system of the workers in the default worker pool. |
| <a name="output_private_service_endpoint_url"></a> [private\_service\_endpoint\_url](#output\_private\_service\_endpoint\_url) | Private service endpoint URL |
| <a name="output_region"></a> [region](#output\_region) | Region cluster is deployed in |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | Resource group ID the cluster is deployed in |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the clusters VPC |
| <a name="output_vpe_url"></a> [vpe\_url](#output\_vpe\_url) | The virtual private endpoint URL of the Kubernetes cluster. |
| <a name="output_workerpools"></a> [workerpools](#output\_workerpools) | Worker pools created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
