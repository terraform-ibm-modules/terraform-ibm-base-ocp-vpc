# Advanced example (mzr, auto-scale, kms, taints)

An advanced example which shows how to create a multi-zone KMS encrypted OCP VPC cluster with custom worker node taints.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A Key Protect instance with 2 root keys, one for cluster encryption, and one for worker block storage encryption.
- A VPC with subnets across 3 zones.
- A public gateway for all the three zones
- A multi-zone (3 zone) KMS encrypted OCP VPC cluster, with worker pools in each zone.
- Auto scaling enabled for the default worker pool.
- Taints against the workers in zone-2 and zone-3.
