---

copyright:
   years: 2025
lastupdated: "[{LAST_UPDATED_DATE}]"

keywords: secure-infrastructure-vpc
subcollection: secure-infrastructure-vpc
content-type: tutorial
account-plan: lite
completion-time: 10m

---

{{site.data.keyword.attribute-definition-list}}

# Deploy {{site.data.keyword.redhat_openshift_notm}} Container platform on IBM Cloud by QuickStart Financial Services Sandbox variation
{: #tutorialQuickStartOCPFCforPOC}
{: toc-content-type="tutorial"}
{: toc-completion-time="10m"}

In this tutorial, you learn how to deploy a [deployable architecture (DA)](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-understand-module-da) from the **IBM Cloud** catalog by using [Cloud Automation for {{site.data.keyword.redhat_openshift_notm}}](https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/deploy-arch-ibm-ocp-vpc-1728a4fd-f561-4cf9-82ef-2b1eeb5da1a8-global#what-you-will-build) as an example. You learn the complete process from browsing the catalog to managing deployed resources along with the wide variety of configurations provided by the Red Hat OpenShift Container Platform on VPC.

The Cloud automation for {{site.data.keyword.redhat_openshift_notm}} platform on VPC enables a scalable and flexible cloud environment for containerized applications with seamless integration to other security and observability services. This architecture can be deployed independently while also serving as a foundational deployable architecture for other architectures.

This architecture enables the deployment of a {{site.data.keyword.redhat_openshift_notm}} cluster within a Virtual Private Cloud (VPC), offering a secure and scalable environment for running containerized applications.


## Before you begin
{: #beforeQuickStartOCPFCforPOC}

Before you begin configuring deployment of your choice, you need to meet the following must-haves.

* An IBM Cloud account.
* Required IAM roles and related permissions. For more information about the permissions, click the **Permissions** tab on the solution tile.
* An API key. This key is required for automation.

Review the following table and choose the variation to suit your requirements.

|Type of Variation | Description |
|---------------|-------|
|QuickStart - Financial Services Sandbox| Deploy {{site.data.keyword.redhat_openshift_notm}} Container platform in a secure and compliant Virtual Private Cloud (VPC) with minimal setup, which is tailored for demonstration use cases.|
|Standard| Deploy {{site.data.keyword.redhat_openshift_notm}} Container platform in a secure and compliant Virtual Private Cloud (VPC), configured to support production use cases.|
|QuickStart| Deploy {{site.data.keyword.redhat_openshift_notm}} Container platform that uses a lightweight, experimental configuration that enables quick provisioning without the need to configure underlying infrastructure. This minimal setup is tailored for demonstration use cases.|
|[Experimental] Fully Configurable| Deploy {{site.data.keyword.redhat_openshift_notm}} Container platform with fully configurable parameters and intelligently selected defaults. It can seamlessly integrate IBM Cloud services without requiring manual intervention.|
{: caption="Variations"}

Make sure that you have a clear understanding of the purpose behind the variation you intend to deploy. When you select a variation and begin building on it, you cannot switch or scale it down to another variation. For instance, if your goal is to quickly deploy {{site.data.keyword.redhat_openshift_notm}} without worrying much about security and compliance, you might choose the QuickStart variation. However, when you deploy this deployable architecture, you cannot upgrade it to Standard or other variation. { :important}


## Create a project for deployment
{: #CreateAProject-ForQuickStartOCP-FC}

{ :step}

1. Log in to your IBM Cloud account. Search for the **Cloud automation for {{site.data.keyword.redhat_openshift_notm}} Container platform on VPC** Deployment architecture product tile in the **Catalog** and click it.

1. To quickly deploy a {{site.data.keyword.redhat_openshift_notm}} cluster, especially to create a demonstration of a Proof of a Concept or for a development activity, select the **QuickStart** variation.

   This deployment architecture has a set of pre-defined default configurations that helps you to quickly provision a {{site.data.keyword.redhat_openshift_notm}} cluster. Before you go ahead with this deployment, review the **Architecture overview**, **Components**, **Permissions**, and **Security & Compliance** section for details. Also, review the **Summary** and the resources that the deployable architecture creates for you.

1. Click **Add to project**. Choose one of the following options:

   - **Create a new project**: Create a new project.
   - **Add to existing project**: Select an existing project.

   To create a new project, enter the **Name**, **Description**, **Configuration name**, **Region**, and the **Resource group** where you want to create a project.
   Projects are based on [Infrastructure as Code (IaC) approach to deployments]((https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-understanding-projects)).

To explore more options to deploy {{site.data.keyword.redhat_openshift_notm}}, click **Review deployment options**.

## Configure the deployment
{: #ConfigureDeployment-ForQuickStartOCP-FC}
{: step}

1. In your project, go to the **Configurations** tab, then click the deployment architecture you just added to your project and click **Edit**.

1. Review and complete the configurations in the **Details** section that is used for automation.

   - **Name** identifies the deployment architecture.

   - **Source** is the type of deployment architecture that you added to the project.

   - **Version** is the version of the deployment architecture that you added to the project.

   - **Environment** contains properties that are shared across related configurations. Within the configuration, you can override any values that are provided by the environment.

   - **Method** is the authentication and authorization method. To learn more about this security method, check [Using an API key with Secrets Manager to authorize a project to deploy an architecture](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-authorize-project).

   - **Api key** is the API key that is stored in Secrets Manager or a trusted profile.

   - **security_and_compliance_controls** is the profile of controls that are configured in the Security and Compliance Center. The default controls are claimed by the author of the deployable architecture. To use an attachment, you must configure one in the Security and Compliance Center by creating a scope and choosing a profile of controls.

1. Use provided defaults for most of the required basic configurations. Understand and complete the basic configurations in the **Inputs** section.
   - **resource_group** is the existing resource group to provision the resources. If not provided, the default resource group is used.

   - **prefix** is added to all resources created by this solution.

   - **region** is where all the resources are deployed.

   - **size** is the cluster [size](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/blob/main/solutions/quickstart/DA_docs.md).

   - **openshift_version** is the version of the Red Hat OpenShift cluster.

   - **operating_system** is the operating system of the Red Hat OpenShift cluster.

   - **cluster_name** is the name of the Red Hat OpenShift Cluster.

   - **address_prefix** is the IP range that points to a certain location in the VPC.

   - **disable_public_endpoint** disables a public endpoint that allows internet access to the cluster if set true.

   - **disable_outbound_traffic_protection** disables public outbound access from the cluster workers if set true. This setting is only applicable for OpenShift Container Platform 4.15 and later.

   - **use_private_endpoint** forces all API calls to use the private endpoints if set true.

Click **Save** to store your configuration.

## Validate the configuration and deploy
{: #ValidateDeployment-ForQuickStartOCP-FC}
{: step}

You need to validate, approve, and deploy all the resources individually. To automatically approve and deploy these configurations in the required order, you can go to the Project Dashboard, then go to **Manage** and then click **Settings** and turn on the **Auto-deploy**.

1. Click **Validate** to run a pre-deployment check for your solution. Check for any validation warnings or errors. Make corrections if needed. Add a comment and click **Approve**.

   This process takes some time based on your configurations and resources.

1. When you approve the configuration, click **Deploy**.

1. Go to **Activity** in the project dashboard to monitor the status of the deployment. You can view real-time logs and updates to the configurations. The deployment time depends on your configurations and resources.


## Verify the deployment
{: #VerifyTheDeployment-ForQuickStartOCP-FC}
{: step}

Check the **Deployed** status, if deployed, you can go to the **Outputs** and **Resources** in your solution dashboard to verify your deployment. To find out all the resources that are created as part of the deployment, you need a **prefix** set in the deployment configuration. You can go to **Resource List** in the IBM Cloud console and search with the **prefix** to fetch the list of resources.

## Troubleshoot
{: #TroubleshootTheDeployment-ForQuickStartOCP-FC}
{: step}

You can troubleshoot the deployments for some common issues as follows:

* If you observe a **Validation fails** error, check the IAM permissions and resource quotas.

* If you observe a **Deployment timeout** error, verify the network connectivity and resource limits.

To troubleshoot more and get help,

* View deployment logs in the project dashboard.

* Contact IBM Cloud support with your project ID.

* For support, raise an issue in the [repository](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/issues).

## Post deployment steps
{: #PostDeploymentSteps-ForQuickStartOCP-FC}
{: step}

You can update the configuration and deploy it again for the updates to take effect.
You can look for deployable architectures to suit your use-case in the **Catalog** and deploy it in IBM Cloud.
