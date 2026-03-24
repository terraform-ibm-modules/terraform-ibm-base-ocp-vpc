# Landing zone for containerized applications with OpenShift example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-containerized_app_landing_zone-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/containerized_app_landing_zone"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->

:exclamation: **Note:** This file only contains the overview of the **Containerized Applications with Landing Zone Example**. The actual terraform code can be found here - [Containerized-app-landing-zone](https://github.com/terraform-ibm-modules/sample-iac-solutions/tree/main/containerized_app_landing_zone)


This example provides a **terraform implementation** of the secure landing zone architecture - a production-grade Red Hat OpenShift platform on IBM Cloud VPC by providing a fully integrated ecosystem. Rather than just provisioning compute resources, it orchestrates the critical **operational glue** required for enterprise workloads—automatically wiring together **Key Management**, **Secrets Manager**, **Cloud Logs**, **Cloud Monitoring**, **Cloud Object Storage** and **Events Notification**. This comprehensive approach reduces operational overhead and eliminates manual configuration errors, ensuring your environment is secure, observable, and ready.

Secure, Compliant, and Scalable Designed to support a wide range of business needs, the architecture is secure by design and fully configurable. It incorporates robust compliance features, such as **SCC Workload Protection**, while allowing you to tailor specific integrations and worker pools to your requirements. This flexibility enables organizations to standardize on a single, reliable architectural pattern that streamlines security approvals and scales effortlessly with business demand.

### Reference Architecture

![Architecture Diagram](../../reference-architectures/deployable-architecture-ocp-cluster.svg)

### Components

The primary goal of this example is to provision an OpenShift cluster on VPC and automatically configure the necessary supporting services, including:
* `VPC Infrastructure`: The base VPC, subnets, and network access controls (ACLs) for the OpenShift cluster. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/landing-zone-vpc/ibm/8.9.1) about the service module.
* `Key Management (KMS)`: Optional provision and configuration of an IBM Key Protect or Hyper Protect Crypto Services (HPCS) instance for encrypting cluster and boot volumes. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/kms-all-inclusive/ibm/5.4.5) about the service module.
* `Secrets Management`: Optional provision and configuration of an IBM Secrets Manager instance to securely store service credentials and other secrets. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/secrets-manager/ibm/2.11.9) about the service module.
* `Cloud Object Storage (COS)`: Optional provision and configuration of COS instances and buckets for flow logs, activity tracker, and other data storage needs. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/cos/ibm/10.5.9) about the service module.
* `Monitoring & Logging`: Optional provision and configuration of IBM Cloud Monitoring and IBM Cloud Logs instances for centralized observability. Learn more about the [Cloud Monitoring](https://registry.terraform.io/modules/terraform-ibm-modules/cloud-monitoring/ibm/1.11.0) and [Cloud Logs](https://registry.terraform.io/modules/terraform-ibm-modules/cloud-logs/ibm/1.10.0) service module.
* `Activity Tracker and Event Routing`: Configure event routing for platform audit logs to a COS bucket or IBM Cloud Logs. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/activity-tracker/ibm/1.5.0) about the service module.
* `Security & Compliance`: Optional integration with IBM Cloud Security and Compliance Center (SCC) Workload Protection. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/scc-workload-protection/ibm/1.16.4) about the service module.
* `VPE Gateways`: Optional configuration of Virtual Private Endpoint (VPE) gateways for secure private connectivity to cloud services. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/vpe-gateway/ibm/4.6.6) about the service module.
* `Event Notifications`: Optional provision and configuration of IBM Cloud Event Notifications for centralized event routing and management, with support for KMS encryption and failed event collection in COS. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/event-notifications/ibm/2.7.0) about the service module.
* `App Configuration`: Optional provision and configuration of IBM Cloud App Configuration for centralized feature flag and property management, securely integrated with KMS and Event Notifications. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/app-configuration/ibm/1.14.2) about the service module.
* `Context-Based Restrictions (CBR)`: Optional support for defining and attaching network access rules (CBR zones and rules) to all supported services (KMS, COS, Secrets Manager) to enforce zero-trust networking. [Learn more](https://registry.terraform.io/modules/terraform-ibm-modules/cbr/ibm/1.34.0) about the service module.
