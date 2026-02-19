# Worker pool module

This module defines and manages worker pools for an IBM Cloud Openshift VPC cluster using the `ibm_container_vpc_worker_pool` resource. It provisions and configures standalone and autoscaling worker pools, handling both pools with optional taints, labels, and encryption configurations.

## Usage

```
module "worker_pools" {
    source              = "terraform-ibm-modules/base-ocp-vpc/ibm//modules/worker-pool"
    version             = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
    vpc_id              = "79cxxxx-xxxx-xxxx-xxxx-xxxxxXX8667"
    resource_group_id   = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
    cluster_id          = "xxXXxXXXxXxXXXXXxxxx"
    vpc_subnets         = {
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
    ignore_worker_pool_size_changes       = false
    allow_default_worker_pool_replacement = false
}
```

You need the following permissions to run this module.

- IAM Services
  - **Kubernetes** service
    - `Administrator` platform access
    - `Manager` service access

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.80.0, < 2.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [ibm_container_vpc_worker_pool.autoscaling_pool](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_worker_pool) | resource |
| [ibm_container_vpc_worker_pool.pool](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_vpc_worker_pool) | resource |
| [ibm_container_vpc_worker_pool.all_pools](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_worker_pool) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_default_worker_pool_replacement"></a> [allow\_default\_worker\_pool\_replacement](#input\_allow\_default\_worker\_pool\_replacement) | (Advanced users) Set to true to allow the module to recreate a default worker pool. If you wish to make any change to the default worker pool which requires the re-creation of the default pool follow these [steps](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#important-considerations-for-terraform-and-default-worker-pool). | `bool` | `false` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | ID of the existing openshift cluster. | `string` | n/a | yes |
| <a name="input_ignore_worker_pool_size_changes"></a> [ignore\_worker\_pool\_size\_changes](#input\_ignore\_worker\_pool\_size\_changes) | Enable if using worker autoscaling. Stops Terraform managing worker count | `bool` | `false` | no |
| <a name="input_ocp_entitlement"></a> [ocp\_entitlement](#input\_ocp\_entitlement) | Value that is applied to the entitlements for OCP cluster provisioning | `string` | `null` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of an existing IBM Cloud resource group where the cluster is grouped. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC instance where this cluster is provisioned. | `string` | n/a | yes |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | Metadata that describes the VPC's subnets. Obtain this information from the VPC where this cluster is created. | <pre>map(list(object({<br/>    id         = string<br/>    zone       = string<br/>    cidr_block = string<br/>  })))</pre> | n/a | yes |
| <a name="input_worker_pools"></a> [worker\_pools](#input\_worker\_pools) | List of worker pools | <pre>list(object({<br/>    subnet_prefix = optional(string)<br/>    vpc_subnets = optional(list(object({<br/>      id         = string<br/>      zone       = string<br/>      cidr_block = string<br/>    })))<br/>    pool_name         = string<br/>    machine_type      = string<br/>    workers_per_zone  = number<br/>    resource_group_id = optional(string)<br/>    operating_system  = string<br/>    labels            = optional(map(string))<br/>    minSize           = optional(number)<br/>    secondary_storage = optional(string)<br/>    maxSize           = optional(number)<br/>    enableAutoscaling = optional(bool)<br/>    boot_volume_encryption_kms_config = optional(object({<br/>      crk             = string<br/>      kms_instance_id = string<br/>      kms_account_id  = optional(string)<br/>    }))<br/>    additional_security_group_ids = optional(list(string))<br/>  }))</pre> | n/a | yes |
| <a name="input_worker_pools_taints"></a> [worker\_pools\_taints](#input\_worker\_pools\_taints) | Optional, Map of lists containing node taints by node-pool name | `map(list(object({ key = string, value = string, effect = string })))` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_workerpools"></a> [workerpools](#output\_workerpools) | Worker pools created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
