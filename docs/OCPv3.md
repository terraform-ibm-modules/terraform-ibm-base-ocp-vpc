# Tutorial: Deploying Cloud Automation for Red Hat OCP in IBM Cloud

This tutorial demonstrates how to deploy a [deployable architecture](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-understand-module-da) from the **IBM Cloud** catalog using [Cloud Automation for Red Hat OpenShift](https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/deploy-arch-ibm-ocp-vpc-1728a4fd-f561-4cf9-82ef-2b1eeb5da1a8-global#what-you-will-build) as an example. You'll learn the complete process from browsing the catalog to managing deployed resources along with the wide variety of configurations provided by the Red Hat OpenShift Container Platform on VPC. 

By the end of this tutorial, you will understand how to:
- Navigate the IBM Cloud catalog for deployable architectures
- Configure and customize architecture parameters
- Deploy infrastructure using IBM Cloud Projects
- Verify and manage deployed resources

## Before you begin

- Ensure you have an IBM Cloud account
- Verify you have the required IAM roles. For more information about the permissions you can navigate to the permissions tab inside the solution tile.
- Have your API key ready (recommended for automation)

## About Cloud Automation for Red Hat OpenShift

The Cloud automation for Red Hat OpenShift Container Platform on VPC enables a scalable and flexible cloud environment for containerized applications with seamless integration to other security and observability services. This architecture can be deployed independently while also serving as a foundational deployable architecture for other architectures. 

This architecture enables the deployment of a Red Hat OpenShift cluster within a Virtual Private Cloud (VPC), offering a secure and scalable environment for running containerized applications.

#### VPC Configuration

You can either provision a new VPC using the **Cloud Automation for VPC** module or deploy the cluster into an existing VPC. The VPC can be configured as single-zone or multi-zone based on your availability requirements.

By default, the automation provisions a **multi-zone (three-zone)** VPC, which serves as the foundation for the OpenShift cluster.

**Default cluster configuration includes:**
- A single worker pool distributed across three availability zones
- Two worker nodes per zone

Additional worker pools can be configured using the `additional_worker_pools` variable.

#### Object Storage

A **Cloud Object Storage (COS)** instance is required to support the internal image registry for OpenShift.

As part of this architecture:
- An object storage bucket is created within the COS instance
- The bucket serves as the internal registry storage for the cluster

To enhance security, the storage bucket can be encrypted using **Key Management Services (KMS)**.

#### Observability

For centralized monitoring and logging, you can enable **Cloud Automation for Observability**, which provides:
- Advanced metrics collection
- Log aggregation
- Operational insights into cluster performance and health

#### Secrets Management

To securely manage sensitive credentials such as Ingress subdomain certificates, enable **Cloud Automation for Secrets Manager**. This allows centralized and secure handling of secrets within the OpenShift deployment.

---

This architecture provides a robust, secure, and production-ready foundation for deploying Red Hat OpenShift. It enables seamless integration with cloud services, enhanced security, and comprehensive observability for your cloud-native workloads.


## Step 1: Access the deployable architecture

1. Log in to your [IBM Cloud account](https://cloud.ibm.com)
2. Click **Catalog** in the top navigation bar and select **Community Registry** from the dropdown
3. In the left sidebar, select **Deployable architectures** under the **Type** section
4. Locate and click on the **Cloud automation for Red Hat OpenShift Container Platform on VPC** tile

## Step 2: Review the Deployable Architecture

1. On the details page, review:
   - **Architecture overview** and **components**, here you will be able to review the architecture diagram, variations, all the different components that are required and also an **overview** about the architecture.
   - **Permissions** tabs will show you all the optional and required roles and permissions you will need for specific add-ons and its deployment.
   - **Cost estimates**
2. Click **Review deployment options** to see available deployment methods

## Step 3: Create a project for deployment

1. Click **Add to project** (recommended approach)
2. Choose one of the following options:
   - **Create a new project**: Enter a project name and description
   - **Add to existing project**: Select from your existing projects
3. If creating a new project:
   - Enter project name 
   - Add description (optional)
   - Add Configuration name
   - Select Region
   - Select the resource group where the project will be created
   - Click **Next**
4. Review the available **Add-ons**:
   - For this tutorial we will be moving forward with the default add-ons which include **Event Notifications**, **Key Protect**, **Observability**, **Secrets Manager**, **VPC** and **Object Storage**. You can learn more about them by going through the individual tiles.
   - For your use case, 
        - Check the boxes for components you want to include
        - Uncheck components you don't need for your specific deployment
        - Review dependencies - some components may be required by others
5. Click **Add to project**

## Step 4: Configure the deployment

1. In your project, navigate to **Configurations**, then click on the solution you just added to your project and select **Edit**
2. **Basic** Configurations (Recommended for beginners)
   - Use provided defaults for most settings
   - Review the **Details** and click **Next**
   - Enter the API Key in **Security** tab then click **Next**
   - In **Configure architecture**, edit all the *required* inputs:
      - **`prefix`** - Enter a unique prefix for resource naming
      - **`default_worker_pool`** include machine_type, workers and os related configs
      - **`existing_vpc_crn`** - The CRN of an existing VPC
      - **`existing_cos_instance_crn`** - The CRN of an already existing Object Storage instance
      - **`enable_platform_metrics`** - You can have 1 instance only of the IBM Cloud Monitoring service per region to collect platform metrics in that location. If an instance is already present in your deployment region, set this to **false**. Setting it to **true** will try creating one and you will encounter an error if an instance is already present in that region.
      - **`logs_routing_tenant_regions`** - To manage platform logs, you must create a tenant in each region that you operate.
      - **`secrets_manager_service_plan`** - Choose from Standard or Trial pricing plan. You can create only one Trial instance of Secrets Manager per account.
      - Most of the fields here will be populated by default but you can choose to edit them.
3. **Advanced** Configurations - You can edit them by turning on **Optional Inputs**. There are a wide variety of advanced configuration options available, which can vary significantly based on your specific scenario and the add-ons you select. This goes to show the advanced capability of Red Hat OCP and its flexibility. You can always choose to use the default values.
   - **Scenario-1:** Additional **`Worker pool`** configurations for specific workload requirements, (Configure worker pools for specialized workloads, scaling, and scheduling control.)
        - **`additional_worker_pools`**- Define extra worker pools for specialized workloads.
        - **`worker_pools_taints`** - Set taints to control pod scheduling on worker pools.
        - **`ignore_worker_pool_size_changes`** - Prevents automation from resizing worker pools.
        - **`allow_default_worker_pool_replacement`** - Permits replacement of the default worker pool if needed.
        - **`default_worker_pool_labels`** - Add custom labels to the default worker pool.
        - **`enable_autoscaling_for_default_pool`** -  Enable autoscaling for the default worker pool.
        - **`default_pool_minimum_number_of_nodes`** - Minimum nodes for the default worker pool.
        - **`default_pool_maximum_number_of_nodes`** - Maximum nodes for the default worker pool.
   - **Scenario-2:** **Private Networking** and **Access Controls** to enhance security and control access by configuring private endpoints and network restrictions.
        - **`use_private_endpoint`**: true to route API calls via private endpoints
        - **`disable_public_endpoint`**: true to create a private cluster
        - **`cluster_config_endpoint_type`**: Choose from default, private, vpe, or link
        - **`verify_worker_network_readiness`**: true to run connectivity tests with kubectl
        - **`disable_outbound_traffic_protection`**: Restrict outbound traffic (OCP 4.15+)
   - **Scenario-3:** **Network** customisations to help customize subnets, CIDRs, and security groups to fit your network architecture.
      - **`existing_subnet_ids`**, **`subnets`**: List of subnet IDs or subnet definitions
      - **`pod_subnet_cidr`**, **`service_subnet_cidr`**: Custom CIDRs for pods and services
      - **`additional_security_group_ids`**: Add more security groups to worker nodes
      - **`custom_security_group_ids`**: Fully override default VPC security groups
      - **`attach_ibm_managed_security_group`**: Attach IBM-managed group (if custom groups used)
      - **`additional_lb_security_group_ids`** - Additional security groups to add to the load balancers associated with the cluster.
      - **`number_of_lbs`** - The number of LBs to associate the additional_lb_security_group_names security group with.
      - **`additional_vpe_security_group_ids`** - Additional security groups to add to all existing load balancers.

   - **Scenario-4:** **Key Management Service (KMS)** to enable encryption and key management for enhanced data security.
      - **`ibmcloud_kms_api_key`**: API key for the KMS account (if different from cluster account)
      - **`existing_kms_instance_crn`**: CRN of the KMS instance
      - **`existing_cluster_kms_key_crn`**: CRN of existing key for Object Storage encryption (optional)
      - **`kms_encryption_enabled_boot_volume`**: true to encrypt block storage volumes
      - **`existing_boot_volume_kms_key_crn`**: CRN of key to encrypt boot volumes (optional)
  
   - **Scenario-5:** **Secrets Manager** to integrate with IBM Cloud Secrets Manager for secure credential management.
      - **`enable_secrets_manager_integration`** - Flag to enable integration with IBM Cloud Secrets Manager
      - **`existing_secrets_manager_instance_crn`** - CRN of your Secrets Manager instance (mandatory if enabled)
      - **`secrets_manager_secret_group_id`** - ID of secret group storing ingress secrets
   - Additional security controls,
        - **`openshift_cluster_cbr_rules`** - The list of context-based restriction rules to create.
    - **`resource_group`** - The name of an existing resource group to provision the cluster.
   - **`addons`** - You can explicitly mention OpenShift-specific add-on versions you require in the form of a Map. You can also set the **`manage_all_addons`** flag to *true* to instruct the DA to manage all the addons by itself.
4.  Click **Save** to store your configuration

## Step 5: Validate and deploy

**Note:** You need to validate, approve and deploy all the resources individually. Now to avoid this you can go to the Project Dashboard, then navigate to **Manage** and then click on **Settings** and turn on the **Auto-deploy** (recommended). This will automatically approve and deploy the configuration changes in the required order.

1. Click **Validate** to run a pre-deployment check for your solution
   - This process takes some time based on your configurations and resources 
   - Review any validation warnings or errors
   - Make corrections if needed
   - Lastly, add a comment and click **Approve**
2. Once you approve, click **Deploy**
3. Navigate to **Activity** in the project dashboard to monitor the status of the deployment
   - View real-time logs and updates
   - Deployment time again depends on your configurations and resources

## Step 6: Verify deployment

Once deployment shows **Deployed** status, 
   - You can navigate to **Outputs** and **Resources** in your solution dashboard to verify your deployment
   - Also, you can go to the **Resource List** in the IBM Cloud console and search with the **prefix** you must have set while configuring your architecture

## Next steps

If you were able to deploy the solution as expected, you successfully deployed your first deployable architecture in IBM Cloud. You can now,
- Modify the configuration and redeploy for changes according to your needs
- Look for your use case specific deployable architecture and deploy it in IBM Cloud


## Troubleshooting

**Common issues**:

- **Validation fails**: Check IAM permissions and resource quotas
- **Deployment timeout**: Verify network connectivity and resource limits

**Getting help**:
- View deployment logs in the project dashboard
- Contact IBM Cloud support with your project ID
- This product is in the community registry and support for this is handled through the originating [repo](https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/issues). If you experience issues, please check for service issues or open an issue in the same repo.

---

**Need help?** Contact IBM Cloud support or visit the [IBM Cloud documentation](https://cloud.ibm.com/docs) for additional resources.