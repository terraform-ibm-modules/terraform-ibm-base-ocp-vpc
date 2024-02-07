# Cluster security group rules example

This example will add security rules to the `kube-<vpcid>` and `kube-<clusterId>` security groups.

The following resources are provisioned by this example:

- A new resource group, if an existing one is not passed in.
- A VPC with subnets in a single zone and public gw attached.
- Security rules to the `kube-<vpcid>` and `kube-<clusterId>` security groups.
- A basic single zone OCP VPC cluster.

You may also be interested in the [example](../custom_sg) that attaches separate security groups to worker nodes, as opposed to adding rules to existing IBM managed security groups.
