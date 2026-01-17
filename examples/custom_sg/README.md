# Attaching custom security groups

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-custom_sg-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/custom_sg"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An example showing how to attach additional security groups to the worker pools, VPE and load balancers:

1. A custom security group, named `custom-cluster-sg`, is specified at cluster creation. This security group is attached to all worker nodes of the cluster, including the worker nodes created after the creation of the cluster.
2. A second custom security group, named `custom-worker-pool-sg`, is specified for one of the `custom-sg` worker pools. This security group is not applied to other worker pools.
3. Three custom security groups, named `custom-master-vpe-sg`, `custom-registry-vpe-sg`, and `custom-kube-api-vpe-sg`, are attached to the three VPEs created by the ROKS-stack: the master VPE, the container registry VPE, and the kubernetes API VPE. This is in addition to the IBM-managed security groups that are still attached to those resources.
4. One custom security group, named `custom-lb-sg`, is attached to the LB created out-of-the-box by the IBM stack.

Furthermore, the default IBM-managed `kube-<clusterId>` security group is linked to all worker nodes of the cluster by utilizing the `attach_ibm_managed_security_group` input variable. It is important to note that, in this configuration, the default VPC security group is not connected to any worker node.

See [Adding VPC security groups to clusters and worker pools during create time](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-security-group&interface=ui#vpc-sg-worker-pool) for further details.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
