# Basic single zone cluster with allowed outbound traffic

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-basic-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/basic"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


A simple example that shows how to provision a basic single zone OCP VPC cluster. Also the outbound traffic is allowed, which is required for accessing the Operator Hub.

The following resources are provisioned by this example:

- A new resource group, if an existing one is not passed in.
- A basic VPC and subnet with public gateway enabled.
- A single zone OCP VPC cluster.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
