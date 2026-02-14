# Advanced security group configuration options

The Terraform module provides options to attach additional security groups to the worker nodes, VPE, and load balancer associated with the cluster.

The [Attaching custom security groups](../examples/custom_sg/) example demonstrates how to use these capabilities.

**Tip**: The [terraform-ibm-security-groups](https://github.com/terraform-ibm-modules/terraform-ibm-security-group) module can be used to create security groups and rules.

## Worker nodes

- Additional security groups can be specified at cluster creation time. These security groups are attached to all worker nodes of the cluster, including additional worker nodes/pools added after the creation of the cluster. See the variable `custom_security_group_ids`.
- Additional security groups can be specified for specific worker pools. These security groups only apply to the worker pool. See the field `additional_security_group_ids` in the variable `worker_pools`.

In all cases, note that:

- The default VPC security is no longer attached to the worker nodes.
- You can opt-out of attaching the IBM-managed cluster security group (named kube-<clusterId>) through the flag `attach_ibm_managed_security_group`.
- It is impossible to change the security groups associated with a cluster after the creation of that cluster.

## VPEs (Virtual Private Endpoints)

- The IBM Cloud OCP stack creates VPEs by default. Prior to version 4.14, a VPE to the master is created. From version 4.14, VPEs to the master, container registry, and IBM Cloud kube APIs are created.
- You can attach additional security groups through the `additional_vpe_security_group_ids` variable.
- The default IBM-managed security group is attached to those VPEs in all cases.

## Load balancers

- The IBM Cloud OCP stack manages the lifecycle of VPC Loadbalancers for your cluster. See the _LoadBalancer_ section in the [Understanding options for exposing apps](https://cloud.ibm.com/docs/openshift?topic=openshift-cs_network_planning).
- By default, one load balancer is created at cluster creation for the default cluster ingress.
- You can attach additional security groups using the `additional_lb_security_group_ids` variable. This set of security groups is attached to all loadbalancers managed by the cluster.
- **Important**: If additional load balancers are added after creating the cluster, for example, by exposing a Kubernetes service of type LoadBalancer, update the `number_of_lbs` variable and re-run this module to attach the extra security groups to the newly created load balancer.
- The default IBM-managed security group is attached to the LBs in all cases.
