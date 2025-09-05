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

docs: https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/reference-architecture/deploy-arch-ibm-ocp-fully-configurable.md

image_source: https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/reference-architecture/deployable-architecture-ocp-cluster.svg

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

Cloud Automation for Red Hat OpenShift on Virtual Private Cloud (VPC) provides a scalable, secure, and production-ready foundation for deploying containerized applications on IBM Cloud. It comes integrated by default with several IBM Cloud services to enhance security, observability, and compliance. Data encryption is enforced using Key Protect and Key Management Services (KMS), while Cloud Object Storage (COS) supports persistent storage and acts as the internal image registry. Secrets Manager is used to securely manage sensitive credentials and certificates, ensuring tighter control over access and authentication. Observability is delivered through Cloud Monitoring, Cloud Logs, and Activity Tracker, while regulatory compliance is supported via Security and Compliance Center and Workload Protection. These integrated capabilities work together to deliver a resilient and well-governed OpenShift environment.

The solution provisions a Red Hat OpenShift cluster within an IBM Cloud VPC, using a default three-zone configuration for high availability. It deploys a single worker pool across all zones, with two worker nodes per zone by default, and allows easy scaling through configurable variables. Cluster and boot volume encryption are enforced, and a dedicated object storage bucket is required to host the internal image registry. This setup ensures strong data protection and infrastructure reliability from the start.

While this architecture is designed to function independently, it also serves as a flexible foundation for more advanced use cases. It supports seamless integration with Cloud Automation for Red Hat OpenShift AI, enabling organizations to deploy AI-driven workloads and accelerate innovation. With its secure, extensible design and managed cloud services, the solution helps enterprises reduce operational complexity and deliver critical applications faster within a governed Red Hat OpenShift ecosystem.

## Architecture diagram
{: #ra-ocp-fully-configurable-architecture-diagram}

![Architecture diagram for the Fully configurable variation of Cloud automation for Red Hat OpenShift Container Platform on VPC](deployable-architecture-ocp-cluster.svg "Architecture diagram of Fully configurable variation of Cloud automation for Red Hat OpenShift Container Platform on VPC deployable architecture"){: caption="Figure 1. Fully configurable variation of Cloud automation for Red Hat OpenShift Container Platform on VPC" caption-side="bottom"}{: external download="deployable-architecture-ocp-cluster.svg"}

## Design concepts
{: #ra-ocp-fully-configurable-design-concepts}

![Design requirements for Red Hat OpenShift Container Platform on VPC](heat-map-deploy-arch-ocp-fully-configurable.svg "Design concepts"){: caption="Figure 2. Scope of the design concepts" caption-side="bottom"}

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
