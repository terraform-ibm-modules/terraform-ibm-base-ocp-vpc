---

copyright:
  years: 2025
lastupdated: "2025-09-03"

keywords:

subcollection: deployable-reference-architectures

authors:
  - name: "Prateek Sharma"

# The release that the reference architecture describes
version: 3.55.6

# Whether the reference architecture is published to Cloud Docs production.
# When set to false, the file is available only in staging. Default is false.
production: true

# Use if the reference architecture has deployable code.
# Value is the URL to land the user in the IBM Cloud catalog details page for the deployable architecture.
# See https://test.cloud.ibm.com/docs/get-coding?topic=get-coding-deploy-button
deployment-url: https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/deploy-arch-ibm-ocp-vpc-1728a4fd-f561-4cf9-82ef-2b1eeb5da1a8-global

docs: https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone/blob/main/reference-architectures/deploy-arch-ibm-ocp-fully-configurable.md

image_source: https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone/blob/main/reference-architectures/deployable-architecture-ocp-cluster.svg

related_links:
  - title: "Cloud automation for Red Hat OpenShift Container Platform on VPC"
    url: "https://cloud.ibm.com/docs/deployable-reference-architectures?topic=deployable-reference-architectures-ocp-fully-configurable"
    description: "A deployable architecture that delivers a scalable and flexible Red Hat OpenShift environment on IBM Cloud Virtual Private Cloud (VPC), with seamless integration to security, observability, and other foundational services for containerized workloads."

use-case: Cybersecurity
industry: Banking,FinancialSector
compliance: FedRAMP

content-type: reference-architecture

---

{{site.data.keyword.attribute-definition-list}}

# Cloud automation for Red Hat OpenShift Container Platform on VPC - Standard - Integrated setup with configurable services
{: #ocp-fully-configurable}
{: toc-content-type="reference-architecture"}
{: toc-industry="Banking,FinancialSector"}
{: toc-use-case="Cybersecurity"}
{: toc-compliance="FedRAMP"}
{: toc-version="1.1.0"}

The Cloud Automation for Red Hat OpenShift Container Platform on Virtual Private Cloud (VPC) offers a scalable and flexible foundation for deploying containerized applications in the IBM cloud. It provides seamless integration with key services such as observability, security, and secrets management, supporting a secure and production-ready OpenShift environment. While it can operate independently, this deployable architecture is also designed to serve as a base for more advanced deployments, including AI-driven workloads using Cloud Automation for Red Hat OpenShift AI, allowing enterprises to accelerate time-to-market for critical applications in a secure and managed OpenShift ecosystem.

This solution provisions a Red Hat OpenShift cluster within a highly configurable Virtual Private Cloud (VPC) environment. Users can opt to use an existing Virtual Private Cloud (VPC) or create a new one using the Cloud foundation for VPC module, which supports both single-zone and multi-zone configurations. By default, a three-zone setup is provisioned to ensure high availability, with a single worker pool spanning all zones and two worker nodes per zone. Additional worker pools can be added easily via configurable variables. The cluster requires a Cloud Object Storage (COS) instance, where a dedicated object storage bucket is used as the internal registry. Cluster and boot volume encryption is enforced using Key Management Services (KMS), enhancing data security.

To support operational visibility and compliance, optional services such as Cloud Automation for Observability and Secrets Manager can be enabled. These provide centralized logging, monitoring, and certificate management, ensuring better control over system health and sensitive credentials. This deployable architecture delivers a secure, resilient, and extensible platform for deploying enterprise-grade Red Hat OpenShift workloads in IBM Cloud.

## Architecture diagram
{: #ra-ocp-fully-configurable-architecture-diagram}

![Architecture diagram for the Fully configurable variation of Cloud automation for Red Hat OpenShift Container Platform on VPC](deployable-architecture-ocp-cluster.svg "Architecture diagram of Fully configurable variation of Cloud automation for Red Hat OpenShift Container Platform on VPC deployable architecture"){: caption="Figure 1. Fully configurable variation of Cloud automation for Red Hat OpenShift Container Platform on VPC" caption-side="bottom"}{: external download="deployable-architecture-ocp-cluster.svg"}

## Design concepts
{: #ra-ocp-fully-configurable-design-concepts}

![Design requirements for Red Hat OpenShift Container Platform on VPC landing zone](heat-map-deploy-arch-ocp-fully-configurable.svg "Design concepts"){: caption="Figure 2. Scope of the design concepts" caption-side="bottom"}

## Requirements
{: #ra-ocp-fully-configurable-requirements}

The following table outlines the requirements that are addressed in this architecture.

| Aspect | Requirements |
|---|---|
| Compute | Kubernetes cluster with minimal machine size and nodes, suitable for low-cost demonstration and development |
| Storage | Kubernetes cluster registry backup (required) |
| Networking | * Multiple VPCs for network isolation. \n * All public inbound and outbound traffic allowed to VPCs. \n * Administration of cluster allowed from public endpoint and web console. \n * Load balancer for cluster workload services. \n * Outbound internet access from cluster. \n * Private network connection between VPCs. |
| Security | * Encryption of all application data in transit and at rest to protect it from unauthorized disclosure. \n * Storage and management of all encryption keys. \n * Protect cluster administration access through IBM Cloud security protocols. |
| Service Management | Automated deployment of infrastructure with IBM Cloud catalog |
{: caption="Table 1. Requirements" caption-side="bottom"}

## Components
{: #ra-ocp-fully-configurable-components}

The following table outlines the products or services used in the architecture for each aspect.

| Aspects | Architecture components | How the component is used |
|---|---|---|
| Compute | Red Hat OpenShift Container Platform | Container execution |
| Storage | IBM Cloud Object Storage | Registry backup for Red Hat OpenShift |
| Networking | * VPC Load Balancer \n * Public Gateway \n * Transit Gateway | * Application load balancing for cluster workloads (automatically created by Red Hat OpenShift service for multi-zone cluster) \n * Cluster access to the internet \n * Private network connectivity between management and workload VPCs |
| Security | * IAM \n * Key Protect | * IBM Cloud Identity and Access Management \n * Management of encryption keys used by Red Hat OpenShift Container Platform |
{: caption="Table 2. Components" caption-side="bottom"}
