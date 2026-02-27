---

copyright:
  years: 2025
lastupdated: "2025-09-03"

keywords:

subcollection: deployable-reference-architectures

authors:
  - name: "Prateek Sharma"

# The release that the reference architecture describes
version: 3.76.4

# Whether the reference architecture is published to Cloud Docs production.
# When set to false, the file is available only in staging. Default is false.
production: true

# Use if the reference architecture has deployable code.
# Value is the URL to land the user in the IBM Cloud catalog details page for the deployable architecture.
deployment-url: https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/deploy-arch-ibm-ocp-vpc-1728a4fd-f561-4cf9-82ef-2b1eeb5da1a8-global

docs: https://cloud.ibm.com/docs/secure-infrastructure-vpc

image_source: https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/reference-architectures/deployable-architecture-ocp-cluster.svg

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
compliance: FedRAMP

content-type: reference-architecture

---

{{site.data.keyword.attribute-definition-list}}

# Landing zone for containerized applications with OpenShift - Standard (Integrated setup with configurable services)

{: #ocp-fully-configurable}
{: toc-content-type="reference-architecture"}
{: toc-industry="Banking,FinancialSector"}
{: toc-use-case="Cybersecurity"}
{: toc-compliance="FedRAMP"}
{: toc-version="3.76.4"}

Landing zone for containerized applications with OpenShift provides a scalable, secure, and production-ready foundation for deploying containerized applications on IBM Cloud. It comes integrated by default with several IBM Cloud services to enhance security, observability, and compliance. Data encryption is enforced using Key Protect and Key Management Services (KMS), while Cloud Object Storage (COS) supports persistent storage and acts as the internal image registry. Secrets Manager is used to securely manage sensitive credentials and certificates, ensuring tighter control over access and authentication. Observability is delivered through Cloud Monitoring, Cloud Logs, and Activity Tracker, while regulatory compliance is supported via Security and Compliance Center and Workload Protection. These integrated capabilities work together to deliver a resilient and well-governed OpenShift environment.

The solution provisions a Red Hat OpenShift cluster within an IBM Cloud VPC, using a default three-zone configuration for high availability. It deploys a single worker pool across all zones, with two worker nodes per zone by default, and allows easy scaling through configurable variables. Cluster and boot volume encryption are enforced, and a dedicated object storage bucket is required to host the internal image registry. This setup ensures strong data protection and infrastructure reliability from the start.

While this architecture is designed to function independently, it also serves as a flexible foundation for more advanced use cases. It supports seamless integration with Cloud Automation for Red Hat OpenShift AI, enabling organizations to deploy AI-driven workloads and accelerate innovation. With its secure, extensible design and managed cloud services, the solution helps enterprises reduce operational complexity and deliver critical applications faster within a governed Red Hat OpenShift ecosystem.

## Architecture diagram

{: #ra-ocp-fully-configurable-architecture-diagram}

![Architecture diagram for the Standard - Integrated setup with configurable services variation of Landing zone for containerized applications with OpenShift](deployable-architecture-ocp-cluster.svg "Architecture diagram of Standard - Integrated setup with configurable services variation of Landing zone for containerized applications with OpenShift deployable architecture"){: caption="Standard - Integrated setup with configurable services variation of Landing zone for containerized applications with OpenShift" caption-side="bottom"}{: external download="deployable-architecture-ocp-cluster.svg"}

## Design concepts

{: #ra-ocp-fully-configurable-design-concepts}

![Design requirements for Landing zone for containerized applications with OpenShift](heat-map-deploy-arch-ocp-fully-configurable.svg "Design concepts"){: caption="Scope of the design concepts" caption-side="bottom"}

## Requirements

{: #ra-ocp-fully-configurable-requirements}

The following table outlines the requirements that are addressed in this architecture.

| Aspect | Requirements |
|---|---|
| Compute | Openshift cluster with minimal machine size and nodes, suitable for low-cost demonstration and development |
| Storage | Openshift cluster registry backup (required) |
| Networking | *Multiple VPCs for network isolation. \n* All public inbound and outbound traffic allowed to VPCs. \n *Administration of cluster allowed from public endpoint and web console. \n* Load balancer for cluster workload services. \n *Outbound internet access from cluster. \n* Private network connection between VPCs. |
| Security | *Encryption of all application data in transit and at rest to protect it from unauthorized disclosure. \n* Storage and management of all encryption keys. \n * Protect cluster administration access through IBM Cloud security protocols. |
| Service Management | Automated deployment of infrastructure with IBM Cloud catalog |
{: caption="Requirements" caption-side="bottom"}

## Components

{: #ra-ocp-fully-configurable-components}

### OpenShift Container Platform (OCP) architecture decisions

| Requirement | Component | Reasons for choice | Alternative choice |
|-------------|-----------|--------------------|--------------------|
| * Provide compute platform for running containers | Red Hat OpenShift Container Platform | Used for container execution and orchestration | Use unmanaged Kubernetes (IKS or self-managed) |
| * Enable persistent and reliable storage for OpenShift needs | IBM Cloud Object Storage | Used for registry backup for Red Hat OpenShift | Use File Storage or Block Storage depending on workload requirements |
| * Support application connectivity and routing  <br>* Provide internet access  <br> * Enable private connectivity across VPCs | VPC Load Balancer, Public Gateway, Transit Gateway | *Application load balancing for cluster workloads (automatically created by Red Hat OpenShift service for multi-zone cluster) <br>* Cluster access to the internet <br> * Private network connectivity between management and workload VPCs | Use classic load balancer or VPN-based connectivity |
| * Secure access and key management for OpenShift | IBM Cloud IAM, Key Protect | *IBM Cloud Identity and Access Management <br>* Management of encryption keys used by Red Hat OpenShift Container Platform | Use Secrets Manager or OS-level access controls |
{: caption="Components" caption-side="bottom"}

### Cluster architecture decisions

{: #ra-ocp-fully-configurable-components-cluster}

| Requirement | Component | Reasons for choice | Alternative choice |
|-------------|-----------|--------------------|--------------------|
| *High availability across zones \n* Fault tolerance for workloads | Multi-zone Red Hat OpenShift cluster | Provides built-in resiliency by distributing worker nodes across three zones | Deploy single-zone clusters with lower availability |
| *Scalable worker infrastructure \n* Cost optimization | Worker pools with configurable node counts | Flexibility to scale nodes horizontally and vertically | Fixed-size clusters with no scaling options |
| * Persistent storage for internal registry | Cloud Object Storage | Highly durable, encrypted, and cost-efficient storage | File or block storage solutions with higher cost |

{: caption="Cluster architecture decisions" caption-side="bottom"}

### Networking architecture decisions

{: #ra-ocp-fully-configurable-components-networking}

| Requirement | Component | Reasons for choice | Alternative choice |
|-------------|-----------|--------------------|--------------------|
| *Enable application traffic distribution \n* Support external workloads | VPC Load Balancer | Provides managed ingress and load balancing | Third-party ingress controllers |
| * Secure connectivity to the internet | Public gateways | Allow outbound connectivity for cluster nodes | Private-only clusters with no internet access |
| *Multi-VPC communication \n* Hub-and-spoke models | Transit Gateway | Provides secure, private connectivity across VPCs | Use VPN gateways or Direct Link |

{: caption="Networking architecture decisions" caption-side="bottom"}

### Security and compliance architecture decisions

{: #ra-ocp-fully-configurable-components-security}

| Requirement | Component | Reasons for choice | Alternative choice |
|-------------|-----------|--------------------|--------------------|
| *Encryption of data at rest \n* Key lifecycle management | Key Protect | Centralized management of encryption keys | Bring Your Own Key (BYOK) solutions |
| * Secure secrets and credentials management | Secrets Manager | Centralized storage and rotation of sensitive credentials | Store secrets directly in OpenShift etcd |
| * Strong authentication and authorization | IAM | Fine-grained access control across users and services | Local OpenShift RBAC only |

{: caption="Security and compliance architecture decisions" caption-side="bottom"}

### Flexibility and customization architecture decisions

{: #ra-ocp-fully-configurable-components-flexibility}

| Requirement | Component | Reasons for choice | Alternative choice |
|-------------|-----------|--------------------|--------------------|
| *Support scaling workloads \n* Enable hybrid deployments | Configurable worker pools | Scale worker nodes to match workload demand | Static cluster sizes |
| *Meet diverse compliance requirements \n* Enable observability integration | Cloud Monitoring, Cloud Logs, Activity Tracker | Provides enterprise-grade visibility and compliance reporting | Third-party monitoring tools |
| * Enable AI-ready workloads | Integration with Cloud Automation for Red Hat OpenShift AI | Prepares foundation for AI/ML use cases | Manual setup of AI services |

{: caption="Flexibility and customization architecture decisions" caption-side="bottom"}

## Key features

{: #ra-ocp-fully-configurable-features}

The Standard - Integrated setup with configurable services variation of Landing zone for containerized applications with OpenShift provides comprehensive capabilities across:

## Red Hat OpenShift Cluster

- **Cluster creation and configuration**: Creates a Red Hat OpenShift cluster on IBM Cloud to manage containerized applications at scale.
- **Enterprise-grade features**: Integrated security, scalability, automation, and compliance-ready capabilities.
- **Multi-zone deployment**: By default, deployed across three zones for high availability.

## Worker pools

- **Customizable worker pools**: Group and manage worker nodes with similar compute configurations.
- **Scalability**: Supports horizontal scaling of worker pools and adjustment of machine profiles.
- **High availability**: Worker nodes can be distributed across multiple zones for resilience.

## Access endpoints

- **Public and Private connectivity**: Offers private and public service endpoints.
- **Enhanced security**: Private-only endpoints can be enabled to restrict access to trusted networks.
- **Administrative flexibility**: Secure cluster management via CLI, API, or web console.

## Ingress controller

- **Traffic management**: Deploys ingress controllers to route external traffic to the correct workloads.
- **TLS termination**: Supports secure HTTPS traffic termination at ingress.
- **Extensibility**: Configurable for custom ingress domains and certificates.

## Object Storage

- **Cluster registry storage**: Configures IBM Cloud Object Storage buckets for OpenShift’s internal image registry.
- **Flexible provisioning**: Use an existing COS instance or create a new one automatically.
- **Resilience**: Supports durable storage with regional resiliency.

## KMS encryption

- **Boot volume and cluster encryption**: Optionally integrates with Key Protect or Hyper Protect Crypto Services.
- **Flexible key options**: Supports creating new encryption keys or using existing ones.
- **Compliance support**: Ensures data at rest is protected in line with regulatory standards.

## Secrets Manager

- **Centralized credential management**: Optionally integrates with IBM Cloud Secrets Manager.
- **Certificate lifecycle management**: Store and manage ingress subdomain TLS certificates.
- **Enhanced governance**: Fine-grained access controls for secret usage.

## Observability

- **Integrated logging and monitoring**: Optional setup with Cloud Monitoring, Cloud Logs, and Activity Tracker.
- **Event routing**: Centralize cluster and workload events for compliance and operations.
- **Scalable telemetry**: Ready to integrate with enterprise observability stacks.

### Kube Audit

- **API activity monitoring**: Captures Kubernetes API server events such as user actions and configuration changes.
- Compliance assurance: Provides audit trails aligned with FedRAMP and enterprise security requirements.
- Centralized visibility: Events routed to observability and SIEM platforms for investigation.
