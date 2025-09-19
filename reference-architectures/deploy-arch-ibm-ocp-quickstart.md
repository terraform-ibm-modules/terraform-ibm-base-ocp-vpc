---

copyright:
  years: 2025
lastupdated: "2025-09-03"

keywords:

subcollection: deployable-reference-architectures

authors:
  - name: "Prateek Sharma"

# The release that the reference architecture describes
version: 3.58.2

# Whether the reference architecture is published to Cloud Docs production.
# When set to false, the file is available only in staging. Default is false.
production: true

# Use if the reference architecture has deployable code.
# Value is the URL to land the user in the IBM Cloud catalog details page
# for the deployable architecture.
# See https://test.cloud.ibm.com/docs/get-coding?topic=get-coding-deploy-button
deployment-url: https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/deploy-arch-ibm-ocp-vpc-1728a4fd-f561-4cf9-82ef-2b1eeb5da1a8-global

docs: https://cloud.ibm.com/docs/secure-infrastructure-vpc

image_source: https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/reference-architectures/deployable-architecture-ocp-cluster-qs.svg

related_links:
  - title: "Landing zone for containerized applications with OpenShift (Standard - Integrated setup with configurable services)"
    url: "https://cloud.ibm.com/docs/deployable-reference-architectures?topic=deployable-reference-architectures-ocp-fully-configurable"
    description: "A deployable architecture that delivers a scalable and flexible Red Hat OpenShift environment on IBM Cloud Virtual Private Cloud (VPC), with seamless integration to security, observability, and other foundational services for containerized workloads."
  - title: "Landing zone for containerized applications with OpenShift (QuickStart - Basic and simple)"
    url: "https://cloud.ibm.com/docs/secure-infrastructure-vpc?topic=secure-infrastructure-ocp-ra-qs"
    description: "A deployable architecture solution that is based on the IBM Cloud for Financial Services reference architecture. This solution delivers a scalable and flexible Red Hat OpenShift environment on IBM Cloud Virtual Private Cloud (VPC), with seamless integration to security, observability, and other foundational services for containerized workloads."
  - title: "Landing zone for containerized applications with OpenShift (Standard - Financial Services edition)"
    url: "https://cloud.ibm.com/docs/deployable-reference-architectures?topic=deployable-reference-architectures-ocp-ra"
    description: "A deployable architecture that creates a secure and compliant Red Hat OpenShift Container Platform workload clusters on a Virtual Private Cloud (VPC) network based on the IBM Cloud for Financial Services reference architecture."
  - title: "Landing zone for containerized applications with OpenShift (QuickStart - Financial Services edition)"
    url: "https://cloud.ibm.com/docs/deployable-reference-architectures?topic=deployable-reference-architectures-roks-ra-qs"
    description: "An introductory, non-certified deployment aligned with the Financial Services Cloud VPCs topology. Not suitable for production workloads or upgrade paths."

use-case: Cybersecurity
industry: Banking,FinancialSector

content-type: reference-architecture

---

{{site.data.keyword.attribute-definition-list}}

# Landing zone for containerized applications with OpenShift - QuickStart (Basic and simple)
{: #ocp-ra-qs}
{: toc-content-type="reference-architecture"}
{: toc-industry="Banking,FinancialSector"}
{: toc-use-case="Cybersecurity"}
{: toc-version="3.58.2"}

The QuickStart variation of the Landing zone for containerized applications with OpenShift deployable architecture creates a fully customizable Virtual Private Cloud (VPC) environment in a single region. The solution provides a single Red Hat OpenShift cluster in a secure VPC for your workloads. The QuickStart variation is designed to deploy quickly for demonstration and development.

## Architecture diagram
{: #ra-ocp-qs-architecture-diagram}

![Architecture diagram for the QuickStart variation of Landing zone for containerized applications with OpenShift](deployable-architecture-ocp-cluster-qs.svg "Architecture diagram of QuickStart variation of Landing zone for containerized applications with OpenShift deployable architecture"){: caption="QuickStart variation of Landing zone for containerized applications with OpenShift" caption-side="bottom"}{: external download="deployable-architecture-ocp-cluster-qs.svg"}

## Design concepts
{: #ra-ocp-qs-design-concepts}

![Design requirements for Landing zone for containerized applications with OpenShift](heat-map-deploy-arch-ocp-quickstart.svg "Design concepts"){: caption="Scope of the design concepts" caption-side="bottom"}

## Requirements
{: #ra-ocp-qs-requirements}

The following table outlines the requirements that are addressed in this architecture.

| Requirement | Component | Reasons for choice | Alternative choice |
|-------------|-----------|--------------------|--------------------|
| * Provide low-cost compute for demonstration and development workloads | Kubernetes cluster with minimal machine size and nodes | Keeps cost low while still supporting containerized workloads | Use a larger production-grade cluster configuration |
| * Ensure registry backup is available for the cluster | Kubernetes cluster registry backup | Provides backup of images and configurations required by Red Hat OpenShift | Use external object storage for registry backup |
| * Support network isolation with multiple VPCs  <br> * Allow inbound and outbound traffic  <br> * Enable cluster administration from public endpoints  <br> * Provide load balancing for workloads  <br> * Enable outbound internet access  <br> * Allow private connectivity between VPCs | Multiple VPCs, Public Gateway, Load Balancer, VPC peering | Delivers connectivity, isolation, and access for cluster workloads and administration | Use a single VPC with simplified connectivity and no private interconnect |
| * Encrypt application data in transit and at rest  <br> * Manage encryption keys securely  <br> * Protect cluster administration access | IBM Cloud IAM, Key Protect | Ensures security of data, keys, and cluster access through IBM Cloud protocols | Use Secrets Manager or OS-level access controls |
| * Automate infrastructure provisioning | IBM Cloud Catalog | Provides automated deployment of infrastructure services | Manual configuration of infrastructure components |
{: caption="Requirements" caption-side="bottom"}

## Components
{: #ra-ocp-qs-components}

The following table outlines the products or services used in the architecture for each aspect.

| Aspects | Architecture components | How the component is used |
|---|---|---|
| Compute | Red Hat OpenShift Container Platform | Container execution |
| Storage | IBM Cloud Object Storage | Registry backup for Red Hat OpenShift |
| Networking | * VPC Load Balancer \n * Public Gateway \n * Transit Gateway | * Application load balancing for cluster workloads (automatically created by Red Hat OpenShift service for multi-zone cluster) \n * Cluster access to the internet \n * Private network connectivity between management and workload VPCs |
| Security | * IAM \n * Key Protect | * IBM Cloud Identity and Access Management \n * Management of encryption keys used by Red Hat OpenShift Container Platform |
{: caption="Components" caption-side="bottom"}
