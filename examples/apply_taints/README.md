# Apply Taints Example

 - This example provisions OCP cluster and set taints for worker pools.
 - The example also enables a key protect provider for the cluster, as well as the required COS instance.
 - The OCP cluster created has a private endpoint.

 ## Private Cluster

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
  disable_public_endpoint         = true
  ## verify_worker_network_readiness should be set to false when runtime does not have access to the kube-api-server.
  ## For example, if we are running terraform apply from a vsi server which is connected to the cluster vpc using a vpn or transit gateway that time verify_worker_network_readiness can be set to true.
  verify_worker_network_readiness = false
}

```
