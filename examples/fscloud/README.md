# Financial Services Cloud profile example

An end-to-end example that uses the [Profile for IBM Cloud Framework for Financial Services](../../modules/fscloud) to deploy an instance of the base OCP VPC module.

The example uses the IBM Cloud Terraform provider to create the following infrastructure:

- A resource group, if one is not passed in
- A sample virtual private cloud (VPC)
- A COS instance for use by the OCP cluster
- A context-based restriction (CBR) rule to only allow COS Instance to be accessible from within the VPC
- OCP cluster in a VPC with the default worker pool deployed across 3 availability zones
- Also uses Hyper Protect Crypto Service for the cluster and boot volume encryption


:exclamation: **Important:** OCP provisions a COS bucket, but you cannot use your own encryption keys. This will fail the requirement for Cloud Object Storage to be enabled with customer-managed encryption and Keep Your Own Key (KYOK).
Once the service supports this the profile will be updated. Until that time it is for educational purposes only.

Outside the OCP Cluster, other parts of the infrastructure do not necessarily comply.

## Before you begin

- You need a Hyper Protect Crypto Services instance and keys for the worker and master encryption available in the region that you want to deploy your OCP Cluster instance to.
