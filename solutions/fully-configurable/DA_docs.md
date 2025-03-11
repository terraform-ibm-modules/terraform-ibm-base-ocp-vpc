# Configuring complex inputs for OCP in IBM Cloud projects
Several optional input variables in the OCP cluster [deployable architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You can specify these inputs when you configure your deployable architecture.

- [Addons](#options-with-addons) (`addons`)
- [Worker Pools](#options-with-worker-pools) (`worker_pools`)
- [Worker Pool Taints](#options-with-worker-pools-taints) (`worker_pools_taints`)
- [Additional VPE Security IDs](#options-with-additional-vpe-security-group-ids) (`additional_vpe_security_group_ids`)
- [VPC Subnets](#options-with-vpc-subnets) (`vpc_subnets`)
- [Context Based Restrictions](#options-with-cbr) (`cbr_rules`)

## Options with addons <a name="options-with-addons"></a>

This variable configuration allows you to specify which OCP add-ons to install on your cluster and which version of each add-on to use.

### Example for addons

```hcl
addons = {
  cluster-autoscaler = "1.0.4"
  openshift-data-foundation = "4.12.0"
  vpc-file-csi-driver = "1.1.0"
}
```

## Options with worker_pools <a name="options-with-worker-pools"></a>

This variable defines the worker node pools for your OCP cluster, with each pool having its own configuration settings.

### Example for worker_pool_taints

```hcl
worker_pools = [
  {
    subnet_prefix                     = "zone-1"
    pool_name                         = "default"
    machine_type                      = "mx2.4x32"
    workers_per_zone                  = 1
    operating_system                  = "REDHAT_9_64"
    enableAutoscaling                 = true
    minSize                           = 1
    maxSize                           = 6
    boot_volume_encryption_kms_config = {
                                          crk             = "83df6f1c-b2a2-4fff-b39b-b999a59b308c"
                                          kms_instance_id = "c123f59b-b7ce-4893-abd8-03089b34f49c"
                                        }
  },
  {
    subnet_prefix                     = "zone-2"
    pool_name                         = "zone-2"
    machine_type                      = "bx2.4x16"
    workers_per_zone                  = 1
    secondary_storage                 = "300gb.5iops-tier"
    operating_system                  = "REDHAT_9_64"
    boot_volume_encryption_kms_config = {
                                          crk             = "83df6f1c-b2a2-4fff-b39b-b999a59b309c"
                                          kms_instance_id = "c123f59b-b7ce-4893-abd8-03089b34f49c"
                                        }
  },
  {
    subnet_prefix                     = "zone-3"
    pool_name                         = "zone-3"
    machine_type                      = "bx2.4x16"
    workers_per_zone                  = 1
    operating_system                  = "REDHAT_9_64"
    boot_volume_encryption_kms_config = {
                                          crk             = "83df6f1c-b2a2-4fff-b39b-b999a59b301c"
                                          kms_instance_id = "c123f59b-b7ce-4893-abd8-03089b34f49c"
                                        }
  }
]
```

## Options with worker_pool_taints <a name="options-with-worker-pools-taints"></a>

This variable allows you to configure taints for your worker pools in your OCP cluster.

### Example for worker_pool_taints

```hcl
worker_pools_taints = {
  all     = []
  default = []
  zone-1 = [{
    key    = "dedicated"
    value  = "zone-1"
    effect = "NoExecute"
  }]
  zone-2 = [{
    key    = "dedicated"
    value  = "zone-2"
    effect = "NoExecute"
  }]
}
```

## Options with additional_vpe_security_group_ids <a name="options-with-additional-vpe-security-group-ids"></a>

This variable allows you to add extra security groups to the Virtual Private Endpoints (VPEs) that are created with your OCP cluster.

### Example for additional_vpe_security_group_ids

```hcl
additional_vpe_security_group_ids = {
  master = ["sg-master-ocp-vpc-1", "sg-master-ocp-vpc-2"]
  registry = ["sg-resgistry-1"]
  api = ["sg-api-1", "sg-api-2"]
}
```

## Options with vpc_subnets <a name="options-with-vpc-subnets"></a>

This variable defines the Virtual Private Cloud (VPC) subnets where your OCP cluster will be deployed.

### Example for vpc_subnets

```hcl
vpc_subnets = {
  "default" = [
    {
      id = "0717-a4b3c2d1-e5f6-g7h8-i9j0-k1l2m3n4o5p6" # pragma: allowlist secret
      zone = "us-south-1"
      cidr_block = " "10.10.10.0/24"
    },
    {
      id = "0717-b4c3d2e1-f5g6-h7i8-j9k0-l1m2n3o4p5q6" # pragma: allowlist secret
      zone = "us-south-2"
      cidr_block = "10.20.10.0/24"
    },
    {
      id = "0717-c4d3e2f1-g5h6-i7j8-k9l0-m1n2o3p4q5r6" # pragma: allowlist secret
      zone = "us-south-3"
      cidr_block = "10.30.10.0/24"
    }
  ]
}
```

## Options with cbr_rules <a name="options-with-cbr"></a>

This variable allows you to provide a rule for the target service to enforce access restrictions for the service based on the context of access requests. Contexts are criteria that include the network location of access requests, the endpoint type from where the request is sent, etc.

- Variable name: `cbr_rules`.
- Type: A list of objects. Allows only one object representing a rule for the target service
  - `description` (required): The description of the rule to create.
  - `account_id` (required): The IBM Cloud Account ID
  - `rule_contexts` (required): (List) The contexts the rule applies to
      - `attributes` (optional): (List) Individual context attributes
        - `name` (required): The attribute name.
        - `value`(required): The attribute value.

  - `enforcement_mode` (required): The rule enforcement mode can have the following values:
      - `enabled` - The restrictions are enforced and reported. This is the default.
      - `disabled` - The restrictions are disabled. Nothing is enforced or reported.
      - `report` - The restrictions are evaluated and reported, but not enforced.
  - `operations` (optional): The operations this rule applies to
    - `api_types`(required): (List) The API types this rule applies to.
        - `api_type_id`(required):The API type ID
- Default value: An empty list (`[]`).


### Example for cbr_rules

```hcl
cbr_rules = [
  {
  description = "Event Notifications can be accessed from xyz"
  account_id = "defc0df06b644a9cabc6e44f55b3880s."
  rule_contexts= [{
      attributes = [
                {
                  name : "endpointType",
                  value : "private"
                },
                {
                  name  = "networkZoneId"
                  value = "93a51a1debe2674193217209601dde6f" # pragma: allowlist secret
                }
        ]
     }
   ]
  enforcement_mode = "enabled"
  operations = [{
    api_types = [{
     api_type_id = "crn:v1:bluemix:public:context-based-restrictions::::api-type:"
      }]
    }]
  }
]
```
