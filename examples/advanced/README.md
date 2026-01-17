# Advanced example (mzr, auto-scale, kms, taints)

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-advanced-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/advanced"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An advanced example which shows how to create a multi-zone KMS encrypted OCP VPC cluster with custom worker node taints.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A Key Protect instance with 2 root keys, one for cluster encryption, and one for worker block storage encryption.
- A VPC with subnets across 3 zones.
- A public gateway for all the three zones
- A multi-zone (3 zone) KMS encrypted OCP VPC cluster, with worker pools in each zone.
- An additional worker pool named `workerpool` is created and attached to the cluster using the `worker-pool` submodule.
- Auto scaling enabled for the default worker pool.
- Taints against the workers in zone-2 and zone-3.
- Enable Kubernetes API server audit logs.
- A Cloud logs instance
- Logs agent to send logs to the cloud logs.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
