# Financial Services compliant example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-fscloud-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/fscloud"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


This example uses the [Profile for IBM Cloud Framework for Financial Services](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/modules/fscloud) to provision an instance of the base OCP VPC module in a compliant manner.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A Cloud Object Storage instance.
- An Object Storage bucket (for VPC Flow logs).
- A secure Virtual Private Cloud (VPC).
- A context-based restriction (CBR) rule to only allow COS Instance to be accessible from within the VPC.
- A Context-based restriction (CBR) network zone containing the VPC.
- A Context-based restriction network zone containing the schematics service.
- CBR rules that allow only the VPC and schematics to access the OCP cluster over the private endpoint.
- An OCP cluster in a VPC with the default worker pool deployed across 3 availability zones with cluster and boot volume encrypted with the given Hyper Protect Crypto Service root key.

:exclamation: **Important:** OCP provisions a COS bucket, but you cannot use your own encryption keys. This will fail the requirement for Cloud Object Storage to be enabled with customer-managed encryption and Keep Your Own Key (KYOK). In OCP 4.14, COS will become optional to provision a cluster.

## Before you begin

- You need a Hyper Protect Crypto Services instance and keys for the worker and master encryption available in the region that you want to deploy your OCP Cluster instance to.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
