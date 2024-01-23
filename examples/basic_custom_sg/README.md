# Attaching custom security groups

A simple example showing how to create a cluster with the following customization around security groups:
1. A custom security group, named `custom-cluster-sg`, is specified at cluster creation. This security group is attached to all worker nodes of the cluster.
2. A second custom security group, named `custom-worker-pool-sg`, is specified for one of the `custom-sg` worker pool.

In addition, the default IBM-managed `kube-<clusterId>` security group is attached to all worker nodes of the cluster - via the `attach_ibm_managed_security_group` input variable.
Note that in this configuration, the default VPC security group is not attached to any worker node.

See [Adding VPC security groups to clusters and worker pools during create time](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-security-group&interface=ui#vpc-sg-worker-pool) for further details.
