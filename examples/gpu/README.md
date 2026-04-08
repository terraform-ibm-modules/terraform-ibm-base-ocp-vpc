# GPU Worker Pool Example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-gpu-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/gpu">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->


This example illustrates how to create an OpenShift cluster on IBM Cloud VPC with:
1. A default worker pool with basic machines (bx2.4x16) across 3 zones
2. A second worker pool with a single GPU machine (gx3.16x80.l4) in one zone

This configuration is useful for workloads that require both general-purpose compute nodes and specialized GPU nodes for AI/ML workloads.

As with all examples in the Terraform IBM Modules repositories, this code is provided to demonstrate working functionality. You can use it as-is to explore the module's capabilities, or adapt it as a starting point for your own infrastructure configuration.

## Architecture

This example creates:
- A VPC using the landing-zone-vpc module with:
  - Subnets across 3 zones for the default worker pool
  - A separate subnet in zone 1 for the GPU worker pool
  - Public gateways in all 3 zones
- An OpenShift cluster with:
  - Default worker pool: 1 worker per zone (3 total) using bx2.4x16 machines
  - GPU worker pool: 1 worker in zone 1 using gx3.16x80.l4 machine with NVIDIA L4 GPUs
