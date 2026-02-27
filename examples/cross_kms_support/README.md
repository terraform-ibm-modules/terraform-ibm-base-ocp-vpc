# Cross account KMS encryption example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-cross_kms_support-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/cross_kms_support"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


A simple example that shows how to provision a VPC with single subnet in a single zone with a public gateway enabled OCP VPC cluster with cross account KMS encryption.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A basic VPC and subnet with public gateway enabled.
- A single zone OCP VPC cluster configured with KMS encryption for cluster data and worker block storage using a KMS encryption key from another account.
- Will allow all traffic ingress/egress by default.

## Note:
- This requires an `account_id` value (IBM account ID where KMS instance is deployed) in the `kms_config` input variable.
- An IBM IAM service to service authorization policy between VPC cluster and KMS instance is required to set up in the IBM account where KMS instance is created.
- For production use cases this would need to be enhanced by adding more subnets and zones for resiliency and ACLs/Security Groups for network security.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
