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
# Value is the URL to land the user in the IBM Cloud catalog details page
# for the deployable architecture.
# See https://test.cloud.ibm.com/docs/get-coding?topic=get-coding-deploy-button
deployment-url: https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/deploy-arch-ibm-ocp-vpc-1728a4fd-f561-4cf9-82ef-2b1eeb5da1a8-global

docs: https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/reference-architectures/deploy-arch-ibm-ocp-quickstart.md

image_source: https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/reference-architectures/deployable-architecture-ocp-cluster-qs.svg

related_links:
  - title: "Cloud automation for Red Hat OpenShift Container Platform on VPC"
    url: "https://cloud.ibm.com/docs/secure-infrastructure-vpc?topic=secure-infrastructure-vpc-ocp-ra"
    description: "A deployable architecture solution that is based on the IBM Cloud for Financial Services reference architecture. This solution delivers a scalable and flexible Red Hat OpenShift environment on IBM Cloud Virtual Private Cloud (VPC), with seamless integration to security, observability, and other foundational services for containerized workloads."

use-case: Cybersecurity
industry: Banking,FinancialSector

content-type: reference-architecture

---

{{site.data.keyword.attribute-definition-list}}

# Cloud automation for Red Hat OpenShift Container Platform on VPC - QuickStart variation
{: #roks-ra-qs}
{: toc-content-type="reference-architecture"}
{: toc-industry="Banking,FinancialSector"}
{: toc-use-case="Cybersecurity"}
{: toc-version="6.6.0"}

The QuickStart variation of the Cloud automation for Red Hat OpenShift Container Platform on VPC deployable architecture creates a fully customizable Virtual Private Cloud (VPC) environment in a single region. The solution provides a single Red Hat OpenShift cluster in a secure VPC for your workloads. The QuickStart variation is designed to deploy quickly for demonstration and development.

## Architecture diagram
{: #ra-ocp-qs-architecture-diagram}

![Architecture diagram for the QuickStart variation of Cloud automation for Red Hat OpenShift Container Platform on VPC](deployable-architecture-ocp-cluster-qs.svg "Architecture diagram of QuickStart variation of Cloud automation for Red Hat OpenShift Container Platform on VPC deployable architecture"){: caption="Figure 1. QuickStart variation of Cloud automation for Red Hat OpenShift Container Platform on VPC" caption-side="bottom"}{: external download="deployable-architecture-ocp-cluster-qs.svg"}

## Design concepts
{: #ra-ocp-qs-design-concepts}

![Design requirements for Cloud automation for Red Hat OpenShift Container Platform on VPC](heat-map-deploy-arch-ocp-quickstart.svg "Design concepts"){: caption="Figure 2. Scope of the design concepts" caption-side="bottom"}

## Requirements
{: #ra-ocp-qs-requirements}

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
{: #ra-ocp-qs-components}

The following table outlines the products or services used in the architecture for each aspect.

| Aspects | Architecture components | How the component is used |
|---|---|---|
| Compute | Red Hat OpenShift Container Platform | Container execution |
| Storage | IBM Cloud Object Storage | Registry backup for Red Hat OpenShift |
| Networking | * VPC Load Balancer \n * Public Gateway \n * Transit Gateway | * Application load balancing for cluster workloads (automatically created by Red Hat OpenShift service for multi-zone cluster) \n * Cluster access to the internet \n * Private network connectivity between management and workload VPCs |
| Security | * IAM \n * Key Protect | * IBM Cloud Identity and Access Management \n * Management of encryption keys used by Red Hat OpenShift Container Platform |
{: caption="Table 2. Components" caption-side="bottom"}
