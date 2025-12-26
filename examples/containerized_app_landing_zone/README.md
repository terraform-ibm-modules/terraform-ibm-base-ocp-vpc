# Landing zone for containerized applications with OpenShift example

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

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.0, <4.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.78.2, < 2.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.16.1 |
| <a name="requirement_restapi"></a> [restapi](#requirement\_restapi) | >= 2.0.1 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1, < 1.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_activity_tracker"></a> [activity\_tracker](#module\_activity\_tracker) | terraform-ibm-modules/activity-tracker/ibm | 1.5.11 |
| <a name="module_app_config"></a> [app\_config](#module\_app\_config) | terraform-ibm-modules/app-configuration/ibm | 1.14.4 |
| <a name="module_at_cos_bucket"></a> [at\_cos\_bucket](#module\_at\_cos\_bucket) | terraform-ibm-modules/cos/ibm//modules/buckets | 10.8.0 |
| <a name="module_cloud_logs"></a> [cloud\_logs](#module\_cloud\_logs) | terraform-ibm-modules/cloud-logs/ibm | 1.10.11 |
| <a name="module_cloud_logs_buckets"></a> [cloud\_logs\_buckets](#module\_cloud\_logs\_buckets) | terraform-ibm-modules/cos/ibm//modules/buckets | 10.8.0 |
| <a name="module_cloud_monitoring"></a> [cloud\_monitoring](#module\_cloud\_monitoring) | terraform-ibm-modules/cloud-monitoring/ibm | 1.12.7 |
| <a name="module_cos"></a> [cos](#module\_cos) | terraform-ibm-modules/cos/ibm//modules/fscloud | 10.8.0 |
| <a name="module_en_cos_buckets"></a> [en\_cos\_buckets](#module\_en\_cos\_buckets) | terraform-ibm-modules/cos/ibm//modules/buckets | 10.8.0 |
| <a name="module_event_notifications"></a> [event\_notifications](#module\_event\_notifications) | terraform-ibm-modules/event-notifications/ibm | 2.10.24 |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-ibm-modules/kms-all-inclusive/ibm | 5.5.11 |
| <a name="module_logs_agent"></a> [logs\_agent](#module\_logs\_agent) | terraform-ibm-modules/logs-agent/ibm | 1.16.0 |
| <a name="module_metrics_routing"></a> [metrics\_routing](#module\_metrics\_routing) | terraform-ibm-modules/cloud-monitoring/ibm//modules/metrics_routing | 1.12.7 |
| <a name="module_monitoring_agent"></a> [monitoring\_agent](#module\_monitoring\_agent) | terraform-ibm-modules/monitoring-agent/ibm | 1.19.2 |
| <a name="module_ocp_base"></a> [ocp\_base](#module\_ocp\_base) | ../.. | n/a |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform-ibm-modules/resource-group/ibm | 1.4.7 |
| <a name="module_scc_wp"></a> [scc\_wp](#module\_scc\_wp) | terraform-ibm-modules/scc-workload-protection/ibm | 1.16.11 |
| <a name="module_secret_group"></a> [secret\_group](#module\_secret\_group) | terraform-ibm-modules/secrets-manager-secret-group/ibm | 1.3.33 |
| <a name="module_secrets_manager"></a> [secrets\_manager](#module\_secrets\_manager) | terraform-ibm-modules/secrets-manager/ibm | 2.12.10 |
| <a name="module_trusted_profile"></a> [trusted\_profile](#module\_trusted\_profile) | terraform-ibm-modules/trusted-profile/ibm | 3.2.13 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-ibm-modules/landing-zone-vpc/ibm | 8.10.4 |
| <a name="module_vpc_cos_buckets"></a> [vpc\_cos\_buckets](#module\_vpc\_cos\_buckets) | terraform-ibm-modules/cos/ibm//modules/buckets | 10.8.0 |
| <a name="module_vpe_gateway"></a> [vpe\_gateway](#module\_vpe\_gateway) | terraform-ibm-modules/vpe-gateway/ibm | 4.8.12 |

### Resources

| Name | Type |
|------|------|
| [ibm_en_subscription_email.apprapp_email_subscription](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/en_subscription_email) | resource |
| [ibm_en_subscription_email.en_email_subscription](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/en_subscription_email) | resource |
| [ibm_en_topic.en_apprapp_topic](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/en_topic) | resource |
| [ibm_en_topic.en_sm_topic](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/en_topic) | resource |
| [ibm_iam_authorization_policy.cos_secrets_manager_key_manager](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_iam_authorization_policy.en_secrets_manager_key_manager](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [terraform_data.delete_secrets](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_sleep.wait_for_cos_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_en_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_secrets_manager](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_en_destinations.en_apprapp_destinations](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/en_destinations) | data source |
| [ibm_en_destinations.en_sm_destinations](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/en_destinations) | data source |
| [ibm_iam_auth_token.auth_token](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/iam_auth_token) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_event_notifications_email_list"></a> [event\_notifications\_email\_list](#input\_event\_notifications\_email\_list) | The list of email address to target out when an event is triggered | `list(string)` | `[]` | no |
| <a name="input_existing_resource_group_name"></a> [existing\_resource\_group\_name](#input\_existing\_resource\_group\_name) | The name of an existing resource group to provision the resources. | `string` | `"Default"` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud api token | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for name of all resource created by this example | `string` | `"ocp-lz"` | no |
| <a name="input_provider_visibility"></a> [provider\_visibility](#input\_provider\_visibility) | Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. | `string` | `"private"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where resources are created | `string` | `"us-south"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_activity_tracker_cos_target_bucket_name"></a> [activity\_tracker\_cos\_target\_bucket\_name](#output\_activity\_tracker\_cos\_target\_bucket\_name) | he name of the object storage bucket which is set as activity tracker event routing target to collect audit events. |
| <a name="output_activity_tracker_routes"></a> [activity\_tracker\_routes](#output\_activity\_tracker\_routes) | The map of created Activity Tracker Event Routing routes |
| <a name="output_activity_tracker_targets"></a> [activity\_tracker\_targets](#output\_activity\_tracker\_targets) | The map of created Activity Tracker Event Routing targets |
| <a name="output_cloud_logs_crn"></a> [cloud\_logs\_crn](#output\_cloud\_logs\_crn) | The id of the provisioned IBM Cloud Logs instance. |
| <a name="output_cloud_logs_guid"></a> [cloud\_logs\_guid](#output\_cloud\_logs\_guid) | The guid of the provisioned IBM Cloud Logs instance. |
| <a name="output_cloud_logs_name"></a> [cloud\_logs\_name](#output\_cloud\_logs\_name) | The name of the provisioned IBM Cloud Logs instance. |
| <a name="output_cloud_monitoring_access_key"></a> [cloud\_monitoring\_access\_key](#output\_cloud\_monitoring\_access\_key) | The IBM Cloud Monitoring access key for agents to use |
| <a name="output_cloud_monitoring_access_key_name"></a> [cloud\_monitoring\_access\_key\_name](#output\_cloud\_monitoring\_access\_key\_name) | The name of the IBM Cloud Monitoring access key for agents to use |
| <a name="output_cloud_monitoring_crn"></a> [cloud\_monitoring\_crn](#output\_cloud\_monitoring\_crn) | The id of the provisioned IBM Cloud Monitoring instance. |
| <a name="output_cloud_monitoring_guid"></a> [cloud\_monitoring\_guid](#output\_cloud\_monitoring\_guid) | The guid of the provisioned IBM Cloud Monitoring instance. |
| <a name="output_cloud_monitoring_name"></a> [cloud\_monitoring\_name](#output\_cloud\_monitoring\_name) | The name of the provisioned IBM Cloud Monitoring instance. |
| <a name="output_cluster_crn"></a> [cluster\_crn](#output\_cluster\_crn) | The Cloud Resource Name (CRN) of the provisioned OpenShift cluster. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The unique identifier assigned to the provisioned OpenShift cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the provisioned OpenShift cluster. |
| <a name="output_cos_instance_crn"></a> [cos\_instance\_crn](#output\_cos\_instance\_crn) | COS instance crn |
| <a name="output_cos_instance_guid"></a> [cos\_instance\_guid](#output\_cos\_instance\_guid) | COS instance guid |
| <a name="output_events_notification_crn"></a> [events\_notification\_crn](#output\_events\_notification\_crn) | Event Notification crn |
| <a name="output_events_notification_guid"></a> [events\_notification\_guid](#output\_events\_notification\_guid) | Event Notification guid |
| <a name="output_kms_account_id"></a> [kms\_account\_id](#output\_kms\_account\_id) | The account ID of the KMS instance. |
| <a name="output_kms_guid"></a> [kms\_guid](#output\_kms\_guid) | KMS instance GUID |
| <a name="output_kms_instance_crn"></a> [kms\_instance\_crn](#output\_kms\_instance\_crn) | The CRN of the KMS instance |
| <a name="output_logs_bucket_crn"></a> [logs\_bucket\_crn](#output\_logs\_bucket\_crn) | Logs Cloud Object Storage bucket CRN |
| <a name="output_metrics_bucket_crn"></a> [metrics\_bucket\_crn](#output\_metrics\_bucket\_crn) | Metrics Cloud Object Storage bucket CRN |
| <a name="output_network_acls"></a> [network\_acls](#output\_network\_acls) | List of shortnames and IDs of network ACLs. |
| <a name="output_ocp_version"></a> [ocp\_version](#output\_ocp\_version) | The version of OpenShift running on the provisioned cluster. |
| <a name="output_private_path_subnet_id"></a> [private\_path\_subnet\_id](#output\_private\_path\_subnet\_id) | The IDs of the subnets. |
| <a name="output_public_gateways"></a> [public\_gateways](#output\_public\_gateways) | Map of the public gateways by zone. |
| <a name="output_scc_workload_protection_crn"></a> [scc\_workload\_protection\_crn](#output\_scc\_workload\_protection\_crn) | SCC Workload Protection instance CRN |
| <a name="output_scc_workload_protection_id"></a> [scc\_workload\_protection\_id](#output\_scc\_workload\_protection\_id) | SCC Workload Protection instance ID |
| <a name="output_scc_workload_protection_name"></a> [scc\_workload\_protection\_name](#output\_scc\_workload\_protection\_name) | SCC Workload Protection instance name |
| <a name="output_secrets_manager_crn"></a> [secrets\_manager\_crn](#output\_secrets\_manager\_crn) | CRN of the Secrets Manager instance |
| <a name="output_secrets_manager_guid"></a> [secrets\_manager\_guid](#output\_secrets\_manager\_guid) | GUID of Secrets Manager instance |
| <a name="output_secrets_manager_region"></a> [secrets\_manager\_region](#output\_secrets\_manager\_region) | Region of the Secrets Manager instance |
| <a name="output_subnet_detail_list"></a> [subnet\_detail\_list](#output\_subnet\_detail\_list) | A list of subnets containing names, CIDR blocks, and zones. |
| <a name="output_subnet_detail_map"></a> [subnet\_detail\_map](#output\_subnet\_detail\_map) | A map of subnets containing IDs, CIDR blocks, and zones. |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | The IDs of the subnets. |
| <a name="output_subnet_zone_list"></a> [subnet\_zone\_list](#output\_subnet\_zone\_list) | A list of subnet IDs and subnet zones. |
| <a name="output_vpc_crn"></a> [vpc\_crn](#output\_vpc\_crn) | CRN of the VPC created. |
| <a name="output_vpc_flow_logs"></a> [vpc\_flow\_logs](#output\_vpc\_flow\_logs) | Details of the VPC flow logs collector. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC created. |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | Name of the VPC created. |
| <a name="output_vpe_crn"></a> [vpe\_crn](#output\_vpe\_crn) | The CRN of the endpoint gateway. |
| <a name="output_vpe_ips"></a> [vpe\_ips](#output\_vpe\_ips) | The reserved IPs for endpoint gateways. |
| <a name="output_vpn_gateways_data"></a> [vpn\_gateways\_data](#output\_vpn\_gateways\_data) | Details of VPN gateways data. |
| <a name="output_vpn_gateways_name"></a> [vpn\_gateways\_name](#output\_vpn\_gateways\_name) | List of names of VPN gateways. |
| <a name="output_workerpools"></a> [workerpools](#output\_workerpools) | A list of worker pools associated with the provisioned cluster |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
