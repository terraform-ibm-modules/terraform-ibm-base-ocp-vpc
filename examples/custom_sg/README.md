# Attaching custom security groups

An example showing how to attach additional security groups to the worker pools, VPE and load balancers:

1. A custom security group, named `custom-cluster-sg`, is specified at cluster creation. This security group is attached to all worker nodes of the cluster, including the worker nodes created after the creation of the cluster.
2. A second custom security group, named `custom-worker-pool-sg`, is specified for one of the `custom-sg` worker pools. This security group is not applied to other worker pools.
3. Three custom security groups, named `custom-master-vpe-sg`, `custom-registry-vpe-sg`, and `custom-api-vpe-sg`, are attached to the three VPEs created by the ROKS-stack: the master VPE, the container registry VPE, and the kubernetes API VPE. This is in addition to the IBM-managed security groups that are still attached to those resources.
4. One custom security group, named `custom-kube-api-vpe-sg`, is attached to the LB created out-of-the-box by the IBM stack.

Furthermore, the default IBM-managed `kube-<clusterId>` security group is linked to all worker nodes of the cluster by utilizing the `attach_ibm_managed_security_group` input variable. It is important to note that, in this configuration, the default VPC security group is not connected to any worker node.

See [Adding VPC security groups to clusters and worker pools during create time](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-security-group&interface=ui#vpc-sg-worker-pool) for further details.
