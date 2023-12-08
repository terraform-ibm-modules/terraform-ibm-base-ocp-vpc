# Cross account KMS encryption example

A simple example that shows how to provision a VPC with single subnet in a single zone with a public gateway enabled OCP VPC cluster with cross account KMS encryption.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A basic VPC and subnet with public gateway enabled.
- A single zone OCP VPC cluster configured with KMS encryption for cluster data and worker block storage using a KMS encryption key from another account.
- Will allow all traffic ingress/egress by default.
- For production use cases this would need to be enhanced by adding more subnets and zones for resiliency and ACLs/Security Groups for network security.

## Note:
- This requires an `account_id` (IBM account ID where KMS instance is deployed) value in the `kms_config` input variable.
- An IBM IAM service to service authorization policy between VPC cluster and KMS instance is required to set up in the IBM account where KMS instance is created.
