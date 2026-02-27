# 2 MZR clusters in same VPC example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-multiple_mzr_clusters-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/multiple_mzr_clusters"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


This is an example of creating 2 MZR clusters in same VPC, and deploying the _observability agents_ in the clusters.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A basic VPC and two subnets with two public gateways enabled in 2 zones.
- Two multi zone OCP Clusters.
- One Observability Instance.
- Two Observability Agents.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
