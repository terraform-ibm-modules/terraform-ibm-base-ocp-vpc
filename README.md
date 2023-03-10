<!-- BEGIN MODULE HOOK -->

<!-- Update the title to match the module name and add a description -->

# terraform-ibm-base-ocp-vpc module

<!-- UPDATE BADGE: Update the link for the badge below-->

[![Stable (With quality checks)](https://img.shields.io/badge/Status-Stable%20(With%20quality%20checks)-green)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)[![Build status](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/actions/workflows/ci.yml/badge.svg)](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/actions/workflows/ci.yml)[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/releases/latest)[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

A module for provisioning an IBM Cloud Red Hat OpenShift cluster on VPC Gen2. The module either creates the required Cloud Object Storage instance or uses an existing instance. The module also supports optionally passing a key management configuration for secret encryption.

## Before you begin

- Make sure that you have a recent version of the [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- Make sure that you have a recent version of the [IBM Cloud Kubernetes service CLI](https://cloud.ibm.com/docs/containers?topic=containers-kubernetes-service-cli)



## Usage
```hcl
# Replace "master" with a GIT release version to lock into a specific release
module "ocp_base" {
  # update this value to the value of your IBM Cloud API key
  ibmcloud_api_key     = "ibm cloud api key" # pragma: allowlist secret
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc.git?ref=master"
  cluster_name         = "example-cluster-name"
  # modify the value for resource_group_id with and id of a group you own
  resource_group_id    = "id of existing resource group"
  region               = "us-south"
  force_delete_storage = true
  vpc_id               = "id of existing VPC"
  ## obtain the below values from the targeted VPC and adjust to the number of zones,
  ## subnets, subnet name, cidr_block, id, zone
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
}

```

## Required IAM access policies
You need the following permissions to run this module.

- Account Management
    - **All Identity and Access Enabled** service
        - `Viewer` platform access
    - **All Resource Groups** service
        - `Viewer` platform access
- IAM Services
    - **Cloud Object Storage** service
        - `Editor` platform access
        - `Manager` service access
    - **Kubernetes** service
        - `Administrator` platform access
        - `Manager` service access
    - **VPC Infrastructure** service
        - `Administrator` platform access
        - `Manager` service access

## Note :
 - One worker pool should always be named as `default`. Refer [issue 2849](https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849) for further details.

<!-- BEGIN EXAMPLES HOOK -->
## Examples

- [ Apply Taints Example](examples/apply_taints)
- [ Existing COS](examples/existing_cos)
- [ 2 MZR clusters in same VPC](examples/multiple_mzr_clusters)
- [ Single Zone Cluster](examples/single_zone_cluster)
- [ Standard Example](examples/standard)
<!-- END EXAMPLES HOOK -->

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.49.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [ibm_container_vpc_cluster.autoscaling_cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_cluster) | resource |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_cluster) | resource |
| [ibm_container_vpc_worker_pool.autoscaling_pool](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_worker_pool) | resource |
| [ibm_container_vpc_worker_pool.pool](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_worker_pool) | resource |
| [ibm_resource_instance.cos_instance](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/resource_instance) | resource |
| [null_resource.confirm_network_healthy](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.reset_api_key](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_cluster_versions.cluster_versions](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_versions) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name that will be assigned to the provisioned cluster | `string` | n/a | yes |
| <a name="input_cluster_ready_when"></a> [cluster\_ready\_when](#input\_cluster\_ready\_when) | The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady | `string` | `"IngressReady"` | no |
| <a name="input_cos_name"></a> [cos\_name](#input\_cos\_name) | Name of the COS instance to provision. New instance only provisioned if `use_existing_cos = false`. Default: `<cluster_name>_cos` | `string` | `null` | no |
| <a name="input_disable_public_endpoint"></a> [disable\_public\_endpoint](#input\_disable\_public\_endpoint) | Flag indicating that the public endpoint should be enabled or disabled | `bool` | `false` | no |
| <a name="input_existing_cos_id"></a> [existing\_cos\_id](#input\_existing\_cos\_id) | The COS id of an already existing COS instance. Only required if 'use\_existing\_cos = true' | `string` | `null` | no |
| <a name="input_force_delete_storage"></a> [force\_delete\_storage](#input\_force\_delete\_storage) | Flag indicating whether or not to delete attached storage when destroying the cluster - Default: false | `bool` | `false` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | APIkey that's associated with the account to use, set via environment variable TF\_VAR\_ibmcloud\_api\_key | `string` | n/a | yes |
| <a name="input_ignore_worker_pool_size_changes"></a> [ignore\_worker\_pool\_size\_changes](#input\_ignore\_worker\_pool\_size\_changes) | Enable if using worker autoscaling. Stops Terraform managing worker count | `bool` | `false` | no |
| <a name="input_kms_config"></a> [kms\_config](#input\_kms\_config) | Use to attach a Key Protect instance to the cluster | <pre>object({<br>    crk_id           = string<br>    instance_id      = string<br>    private_endpoint = optional(bool, true) # defaults to true<br>  })</pre> | `null` | no |
| <a name="input_ocp_entitlement"></a> [ocp\_entitlement](#input\_ocp\_entitlement) | Value that is applied to the entitlements for OCP cluster provisioning | `string` | `"cloud_pak"` | no |
| <a name="input_ocp_version"></a> [ocp\_version](#input\_ocp\_version) | The version of the OpenShift cluster that should be provisioned (format 4.x). This is only used during initial cluster provisioning, but ignored for future updates. If no value is passed, or the string 'latest' is passed, the current latest OCP version will be used. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where the cluster will be provisioned. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The Id of an existing IBM Cloud resource group where the cluster will be grouped. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Metadata labels describing this cluster deployment, i.e. test | `list(string)` | `[]` | no |
| <a name="input_use_existing_cos"></a> [use\_existing\_cos](#input\_use\_existing\_cos) | Flag indicating whether or not to use an existing COS instance | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Id of the VPC instance where this cluster will be provisioned | `string` | n/a | yes |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | Metadata that describes the VPC's subnets. Obtain this information from the VPC where this cluster will be created | <pre>map(list(object({<br>    id         = string<br>    zone       = string<br>    cidr_block = string<br>  })))</pre> | n/a | yes |
| <a name="input_worker_pools"></a> [worker\_pools](#input\_worker\_pools) | List of worker pools | <pre>list(object({<br>    subnet_prefix     = string<br>    pool_name         = string<br>    machine_type      = string<br>    workers_per_zone  = number<br>    resource_group_id = optional(string)<br>    labels            = optional(map(string))<br>  }))</pre> | <pre>[<br>  {<br>    "machine_type": "bx2.4x16",<br>    "pool_name": "default",<br>    "subnet_prefix": "zone-1",<br>    "workers_per_zone": 2<br>  },<br>  {<br>    "machine_type": "bx2.4x16",<br>    "pool_name": "zone-2",<br>    "subnet_prefix": "zone-2",<br>    "workers_per_zone": 2<br>  },<br>  {<br>    "machine_type": "bx2.4x16",<br>    "pool_name": "zone-3",<br>    "subnet_prefix": "zone-3",<br>    "workers_per_zone": 2<br>  }<br>]</pre> | no |
| <a name="input_worker_pools_taints"></a> [worker\_pools\_taints](#input\_worker\_pools\_taints) | Optional, Map of lists containing node taints by node-pool name | `map(list(object({ key = string, value = string, effect = string })))` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_crn"></a> [cluster\_crn](#output\_cluster\_crn) | CRN for the created cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of cluster created |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the created cluster |
| <a name="output_cos_crn"></a> [cos\_crn](#output\_cos\_crn) | CRN of the COS instance |
| <a name="output_ingress_hostname"></a> [ingress\_hostname](#output\_ingress\_hostname) | Ingress hostname |
| <a name="output_ocp_version"></a> [ocp\_version](#output\_ocp\_version) | Openshift Version of the cluster |
| <a name="output_private_service_endpoint_url"></a> [private\_service\_endpoint\_url](#output\_private\_service\_endpoint\_url) | Private service endpoint URL |
| <a name="output_public_service_endpoint_url"></a> [public\_service\_endpoint\_url](#output\_public\_service\_endpoint\_url) | Public service endpoint URL |
| <a name="output_region"></a> [region](#output\_region) | Region cluster is deployed in |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | Resource group ID the cluster is deployed in |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the clusters VPC |
| <a name="output_workerpools"></a> [workerpools](#output\_workerpools) | Worker pools created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN CONTRIBUTING HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
<!-- END CONTRIBUTING HOOK -->
