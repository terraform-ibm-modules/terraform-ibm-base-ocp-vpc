# Virtualization example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-virtualization-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/virtualization">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->

<!--
The basic example should call the module(s) stored in this repository with a basic configuration.
Note, there is a pre-commit hook that will take the title of each example and include it in the repos main README.md.
The text below should describe exactly what resources are provisioned / configured by the example.
-->

This example illustrates how to create an OpenShift cluster on IBM Cloud VPC configured for OpenShift Virtualization.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A landing zone VPC with subnets across 3 zones.
- An OpenShift base cluster configured for Virtualization:
  - Offering set to `openshift-vs` (OpenShift Virtualization Service cluster).
  - Default worker pool of 3 bare metal nodes (`mx3d.metal.64x512`) across 3 zones using Red Hat Enterprise Linux CoreOS (`RHCOS`).
  - Network plugin configured to use `OVNKubernetes`.
  - The `openshift-data-foundation` (ODF) addon installed and configured for virtualization (with `setDefaultStorageClassForVirtualization` parameter).
- Outbound traffic protection is disabled (allows outbound traffic), which is required for accessing the Operator Hub in the OpenShift console.
