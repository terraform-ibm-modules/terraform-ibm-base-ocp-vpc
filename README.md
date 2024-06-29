# Red Hat OpenShift VPC cluster on IBM Cloud module

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Catalog release](https://img.shields.io/badge/release-IBM%20Cloud%20Catalog-3662FF?logo=ibm)](https://cloud.ibm.com/catalog/modules/terraform-ibm-base-ocp-vpc-8531b562-91d5-4974-a195-5dff72ef2a5d-global)

Use this module to provision an [IBM Cloud Red Hat OpenShift cluster](https://cloud.ibm.com/docs/openshift?topic=openshift-getting-started) on VPC Gen2. The module either creates the required Cloud Object Storage instance or uses an existing instance. The module also supports optionally passing a key management configuration for secret encryption and boot volume encryption.

Optionally, the module supports advanced security group management for the worker nodes, VPE, and load balancer associated with the cluster. This feature allows you to configure security groups for the cluster's worker nodes, VPE, and load balancer.

:exclamation: **Important:** You can't update Red Hat OpenShift cluster nodes by using this module. The Terraform logic ignores updates to prevent possible destructive changes.

### Before you begin

- Ensure that you have an up-to-date version of the [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started).
- Ensure that you have an up-to-date version of the [IBM Cloud Kubernetes service CLI](https://cloud.ibm.com/docs/containers?topic=containers-kubernetes-service-cli).
- Ensure that you have an up-to-date version of the [IBM Cloud VPC Infrastructure service CLI](https://cloud.ibm.com/docs/vpc?topic=vpc-vpc-reference). Only required if providing additional security groups with the `var.additional_lb_security_group_ids`.
- Ensure that you have an up-to-date version of the [jq](https://jqlang.github.io/jq)

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-base-ocp-vpc](#terraform-ibm-base-ocp-vpc)
* [Submodules](./modules)
    * [fscloud](./modules/fscloud)
* [Examples](./examples)
    * [2 MZR clusters in same VPC example](./examples/multiple_mzr_clusters)
    * [Advanced example (mzr, auto-scale, kms, taints)](./examples/advanced)
    * [Attaching custom security groups](./examples/custom_sg)
    * [Basic single zone example](./examples/basic)
    * [Cluster security group rules example](./examples/add_rules_to_sg)
    * [Cross account KMS encryption example](./examples/cross_kms_support)
    * [Financial Services compliant example](./examples/fscloud)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

<!-- This heading should always match the name of the root level module (aka the repo name) -->
## terraform-ibm-base-ocp-vpc

### Usage

```hcl
module "ocp_base" {
  source               = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version              = "X.X.X" # Replace "X.X.X" with a release version to lock into a specific release
  cluster_name         = "example-cluster-name"
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
}
```

### Advanced security group options

The Terraform module provides options to attach additional security groups to the worker nodes, VPE, and load balancer associated with the cluster.

The [custom_sg example](./examples/custom_sg/) demonstrates how to use these capabilities.

See the IBM Cloud documentation on this topic [here](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-security-group&interface=ui)

Tip: The [terraform-ibm-security-groups](https://github.com/terraform-ibm-modules/terraform-ibm-security-group) module can be used to create security groups and rules.

#### Worker nodes

- Additional security groups can be specified at cluster creation time. These security groups are attached to all worker nodes of the cluster, including additional worker nodes/pools added after the creation of the cluster. See the variable `custom_security_group_ids`.
- Additional security groups can be specified for specific worker pools. These security groups only apply to the worker pool. See the field `additional_security_group_ids` in the variable `worker_pools`.

In all cases, note that:

- The default VPC security is no longer attached to the worker nodes.
- You can opt-out of attaching the IBM-managed cluster security group (named kube-<clusterId>) through the flag `attach_ibm_managed_security_group`.
- It is impossible to change the security groups associated with a cluster after the creation of that cluster.

#### VPEs (Virtual Private Endpoints)

- The IBM Cloud OCP stack creates VPEs by default. Prior to version 4.14, a VPE to the master is created. From version 4.14, VPEs to the master, container registry, and IBM Cloud kube APIs are created.
- You can attach additional security groups through the `additional_vpe_security_group_ids` variable.
- The default IBM-managed security group is attached to those VPEs in all cases.

#### Load balancers

- The IBM Cloud OCP stack manages the lifecycle of VPC Loadbalancers for your cluster. See the _LoadBalancer_ section in the [Understanding options for exposing apps](https://cloud.ibm.com/docs/openshift?topic=openshift-cs_network_planning).
- By default, one load balancer is created at cluster creation for the default cluster ingress.
- You can attach additional security groups using the `additional_lb_security_group_ids` variable. This set of security groups is attached to all loadbalancers managed by the cluster.
- **Important**: If additional load balancers are added after creating the cluster, for example, by exposing a Kubernetes service of type LoadBalancer, update the `number_of_lbs` variable and re-run this module to attach the extra security groups to the newly created load balancer.
- The default IBM-managed security group is attached to the LBs in all cases.

### Troubleshooting

#### New kube_version message

- When you run a `terraform plan` command, you might get a message about a new version of Kubernetes, as in the following example:

    ```terraform
    kube_version = "4.12.16_openshift" -> "4.12.20_openshift"

    Unless you have made equivalent changes to your configuration, or ignored the relevant attributes using ignore_changes, the following plan may include actions to undo or respond to these changes.
    ```

    A new version is detected because the Kubernetes master node is updated outside of Terraform, and the Terraform state is out of date with that version.

    The Kubernetes version is ignored in the module code, so the infrastructure will not be modified. The message identifies that drift exists in the versions, and after running the `terraform apply` command, the state will be refreshed.

### Required IAM access policies

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

Optionally, you need the following permissions to attach Access Management tags to resources in this module.

- IAM Services
  - **Tagging** service
    - `Administrator` platform access

### Note

- One worker pool should always be named as `default`. Refer [issue 2849](https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849) for further details.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.66.0, < 2.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.16.1, < 3.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1, < 4.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_attach_sg_to_api_vpe"></a> [attach\_sg\_to\_api\_vpe](#module\_attach\_sg\_to\_api\_vpe) | terraform-ibm-modules/security-group/ibm | 2.6.2 |
| <a name="module_attach_sg_to_lb"></a> [attach\_sg\_to\_lb](#module\_attach\_sg\_to\_lb) | terraform-ibm-modules/security-group/ibm | 2.6.2 |
| <a name="module_attach_sg_to_master_vpe"></a> [attach\_sg\_to\_master\_vpe](#module\_attach\_sg\_to\_master\_vpe) | terraform-ibm-modules/security-group/ibm | 2.6.2 |
| <a name="module_attach_sg_to_registry_vpe"></a> [attach\_sg\_to\_registry\_vpe](#module\_attach\_sg\_to\_registry\_vpe) | terraform-ibm-modules/security-group/ibm | 2.6.2 |
| <a name="module_cos_instance"></a> [cos\_instance](#module\_cos\_instance) | terraform-ibm-modules/cos/ibm | 8.5.2 |

### Resources

| Name | Type |
|------|------|
| [ibm_container_addons.addons](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_addons) | resource |
| [ibm_container_vpc_cluster.autoscaling_cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_cluster) | resource |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_cluster) | resource |
| [ibm_container_vpc_worker_pool.autoscaling_pool](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_worker_pool) | resource |
| [ibm_container_vpc_worker_pool.pool](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_worker_pool) | resource |
| [ibm_resource_tag.cluster_access_tag](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/resource_tag) | resource |
| [ibm_resource_tag.cos_access_tag](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/resource_tag) | resource |
| [kubernetes_config_map_v1_data.set_autoscaling](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [null_resource.config_map_status](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.confirm_lb_active](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.confirm_network_healthy](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.reset_api_key](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [ibm_container_addons.existing_addons](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_addons) | data source |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_cluster_versions.cluster_versions](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_versions) | data source |
| [ibm_container_vpc_worker_pool.all_pools](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_worker_pool) | data source |
| [ibm_iam_account_settings.iam_account_settings](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/iam_account_settings) | data source |
| [ibm_iam_auth_token.reset_api_key_tokendata](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/iam_auth_token) | data source |
| [ibm_iam_auth_token.tokendata](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/iam_auth_token) | data source |
| [ibm_is_lbs.all_lbs](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/is_lbs) | data source |
| [ibm_is_virtual_endpoint_gateways.all_vpes](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateways) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | A list of access tags to apply to the resources created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details | `list(string)` | `[]` | no |
| <a name="input_additional_lb_security_group_ids"></a> [additional\_lb\_security\_group\_ids](#input\_additional\_lb\_security\_group\_ids) | Additional security groups to add to the load balancers associated with the cluster. Ensure that the number\_of\_lbs is set to the number of LBs associated with the cluster. This comes in addition to the IBM maintained security group. | `list(string)` | `[]` | no |
| <a name="input_additional_vpe_security_group_ids"></a> [additional\_vpe\_security\_group\_ids](#input\_additional\_vpe\_security\_group\_ids) | Additional security groups to add to all existing load balancers. This comes in addition to the IBM maintained security group. | <pre>object({<br>    master   = optional(list(string), [])<br>    registry = optional(list(string), [])<br>    api      = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_addons"></a> [addons](#input\_addons) | Map of OCP cluster add-on versions to install (NOTE: The 'vpc-block-csi-driver' add-on is installed by default for VPC clusters, however you can explicitly specify it here if you wish to choose a later version than the default one). For full list of all supported add-ons and versions, see https://cloud.ibm.com/docs/containers?topic=containers-supported-cluster-addon-versions | <pre>object({<br>    debug-tool                = optional(string)<br>    image-key-synchronizer    = optional(string)<br>    openshift-data-foundation = optional(string)<br>    vpc-file-csi-driver       = optional(string)<br>    static-route              = optional(string)<br>    cluster-autoscaler        = optional(string)<br>    vpc-block-csi-driver      = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_attach_ibm_managed_security_group"></a> [attach\_ibm\_managed\_security\_group](#input\_attach\_ibm\_managed\_security\_group) | Specify whether to attach the IBM-defined default security group (whose name is kube-<clusterid>) to all worker nodes. Only applicable if custom\_security\_group\_ids is set. | `bool` | `true` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name that will be assigned to the provisioned cluster | `string` | n/a | yes |
| <a name="input_cluster_ready_when"></a> [cluster\_ready\_when](#input\_cluster\_ready\_when) | The cluster is ready when one of the following: MasterNodeReady (not recommended), OneWorkerNodeReady, Normal, IngressReady | `string` | `"IngressReady"` | no |
| <a name="input_cos_name"></a> [cos\_name](#input\_cos\_name) | Name of the COS instance to provision for OpenShift internal registry storage. New instance only provisioned if 'enable\_registry\_storage' is true and 'use\_existing\_cos' is false. Default: '<cluster\_name>\_cos' | `string` | `null` | no |
| <a name="input_custom_security_group_ids"></a> [custom\_security\_group\_ids](#input\_custom\_security\_group\_ids) | Security groups to add to all worker nodes. This comes in addition to the IBM maintained security group if attach\_ibm\_managed\_security\_group is set to true. If this variable is set, the default VPC security group is NOT assigned to the worker nodes. | `list(string)` | `null` | no |
| <a name="input_disable_outbound_traffic_protection"></a> [disable\_outbound\_traffic\_protection](#input\_disable\_outbound\_traffic\_protection) | Whether to allow public outbound access from the cluster workers. This is only applicable for `ocp_version` 4.15 | `bool` | `false` | no |
| <a name="input_disable_public_endpoint"></a> [disable\_public\_endpoint](#input\_disable\_public\_endpoint) | Whether access to the public service endpoint is disabled when the cluster is created. Does not affect existing clusters. You can't disable a public endpoint on an existing cluster, so you can't convert a public cluster to a private cluster. To change a public endpoint to private, create another cluster with this input set to `true`. | `bool` | `false` | no |
| <a name="input_enable_registry_storage"></a> [enable\_registry\_storage](#input\_enable\_registry\_storage) | Set to `true` to enable IBM Cloud Object Storage for the Red Hat OpenShift internal image registry. Set to `false` only for new cluster deployments in an account that is allowlisted for this feature. | `bool` | `true` | no |
| <a name="input_existing_cos_id"></a> [existing\_cos\_id](#input\_existing\_cos\_id) | The COS id of an already existing COS instance to use for OpenShift internal registry storage. Only required if 'enable\_registry\_storage' and 'use\_existing\_cos' are true | `string` | `null` | no |
| <a name="input_force_delete_storage"></a> [force\_delete\_storage](#input\_force\_delete\_storage) | Flag indicating whether or not to delete attached storage when destroying the cluster - Default: false | `bool` | `false` | no |
| <a name="input_ignore_worker_pool_size_changes"></a> [ignore\_worker\_pool\_size\_changes](#input\_ignore\_worker\_pool\_size\_changes) | Enable if using worker autoscaling. Stops Terraform managing worker count | `bool` | `false` | no |
| <a name="input_kms_config"></a> [kms\_config](#input\_kms\_config) | Use to attach a KMS instance to the cluster. If account\_id is not provided, defaults to the account in use. | <pre>object({<br>    crk_id           = string<br>    instance_id      = string<br>    private_endpoint = optional(bool, true) # defaults to true<br>    account_id       = optional(string)     # To attach KMS instance from another account<br>    wait_for_apply   = optional(bool, true) # defaults to true so terraform will wait until the KMS is applied to the master, ready and deployed<br>  })</pre> | `null` | no |
| <a name="input_manage_all_addons"></a> [manage\_all\_addons](#input\_manage\_all\_addons) | Instructs Terraform to manage all cluster addons, even if addons were installed outside of the module. If set to 'true' this module will destroy any addons that were installed by other sources. | `bool` | `false` | no |
| <a name="input_number_of_lbs"></a> [number\_of\_lbs](#input\_number\_of\_lbs) | The number of LBs to associated the additional\_lb\_security\_group\_names security group with. | `number` | `1` | no |
| <a name="input_ocp_entitlement"></a> [ocp\_entitlement](#input\_ocp\_entitlement) | Value that is applied to the entitlements for OCP cluster provisioning | `string` | `null` | no |
| <a name="input_ocp_version"></a> [ocp\_version](#input\_ocp\_version) | The version of the OpenShift cluster that should be provisioned (format 4.x). If no value is specified, the current default version is used. You can also specify `default`. This input is used only during initial cluster provisioning and is ignored for updates. To prevent possible destructive changes, update the cluster version outside of Terraform. | `string` | `null` | no |
| <a name="input_operating_system"></a> [operating\_system](#input\_operating\_system) | The operating system of the workers in the default worker pool. If no value is specified, the current default version OS will be used. See https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_versions#openshift_versions_available . | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where the cluster will be provisioned. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The Id of an existing IBM Cloud resource group where the cluster will be grouped. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Metadata labels describing this cluster deployment, i.e. test | `list(string)` | `[]` | no |
| <a name="input_use_existing_cos"></a> [use\_existing\_cos](#input\_use\_existing\_cos) | Flag indicating whether or not to use an existing COS instance for OpenShift internal registry storage. Only applicable if 'enable\_registry\_storage' is true | `bool` | `false` | no |
| <a name="input_use_private_endpoint"></a> [use\_private\_endpoint](#input\_use\_private\_endpoint) | Set this to true to force all api calls to use the IBM Cloud private endpoints. | `bool` | `false` | no |
| <a name="input_verify_worker_network_readiness"></a> [verify\_worker\_network\_readiness](#input\_verify\_worker\_network\_readiness) | By setting this to true, a script will run kubectl commands to verify that all worker nodes can communicate successfully with the master. If the runtime does not have access to the kube cluster to run kubectl commands, this should be set to false. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Id of the VPC instance where this cluster will be provisioned | `string` | n/a | yes |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | Metadata that describes the VPC's subnets. Obtain this information from the VPC where this cluster will be created | <pre>map(list(object({<br>    id         = string<br>    zone       = string<br>    cidr_block = string<br>  })))</pre> | n/a | yes |
| <a name="input_worker_pools"></a> [worker\_pools](#input\_worker\_pools) | List of worker pools | <pre>list(object({<br>    subnet_prefix = optional(string)<br>    vpc_subnets = optional(list(object({<br>      id         = string<br>      zone       = string<br>      cidr_block = string<br>    })))<br>    pool_name         = string<br>    machine_type      = string<br>    workers_per_zone  = number<br>    resource_group_id = optional(string)<br>    labels            = optional(map(string))<br>    minSize           = optional(number)<br>    maxSize           = optional(number)<br>    enableAutoscaling = optional(bool)<br>    boot_volume_encryption_kms_config = optional(object({<br>      crk             = string<br>      kms_instance_id = string<br>      kms_account_id  = optional(string)<br>    }))<br>    additional_security_group_ids = optional(list(string))<br>  }))</pre> | n/a | yes |
| <a name="input_worker_pools_taints"></a> [worker\_pools\_taints](#input\_worker\_pools\_taints) | Optional, Map of lists containing node taints by node-pool name | `map(list(object({ key = string, value = string, effect = string })))` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_vpe"></a> [api\_vpe](#output\_api\_vpe) | Info about the api VPE, if it exists. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway |
| <a name="output_cluster_crn"></a> [cluster\_crn](#output\_cluster\_crn) | CRN for the created cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of cluster created |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the created cluster |
| <a name="output_cos_crn"></a> [cos\_crn](#output\_cos\_crn) | CRN of the COS instance |
| <a name="output_ingress_hostname"></a> [ingress\_hostname](#output\_ingress\_hostname) | The hostname that was assigned to your Ingress subdomain. |
| <a name="output_kms_config"></a> [kms\_config](#output\_kms\_config) | KMS configuration details |
| <a name="output_master_status"></a> [master\_status](#output\_master\_status) | The status of the Kubernetes master. |
| <a name="output_master_url"></a> [master\_url](#output\_master\_url) | The URL of the Kubernetes master. |
| <a name="output_master_vpe"></a> [master\_vpe](#output\_master\_vpe) | Info about the master, or default, VPE. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway |
| <a name="output_ocp_version"></a> [ocp\_version](#output\_ocp\_version) | Openshift Version of the cluster |
| <a name="output_operating_system"></a> [operating\_system](#output\_operating\_system) | The operating system of the workers in the default worker pool. |
| <a name="output_private_service_endpoint_url"></a> [private\_service\_endpoint\_url](#output\_private\_service\_endpoint\_url) | Private service endpoint URL |
| <a name="output_public_service_endpoint_url"></a> [public\_service\_endpoint\_url](#output\_public\_service\_endpoint\_url) | Public service endpoint URL |
| <a name="output_region"></a> [region](#output\_region) | Region cluster is deployed in |
| <a name="output_registry_vpe"></a> [registry\_vpe](#output\_registry\_vpe) | Info about the registry VPE, if it exists. For more info about schema, see https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_virtual_endpoint_gateway |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | Resource group ID the cluster is deployed in |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the clusters VPC |
| <a name="output_vpe_url"></a> [vpe\_url](#output\_vpe\_url) | The virtual private endpoint URL of the Kubernetes cluster. |
| <a name="output_workerpools"></a> [workerpools](#output\_workerpools) | Worker pools created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
