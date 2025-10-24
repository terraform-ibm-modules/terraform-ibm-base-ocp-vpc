# Worker pool example

This example demonstrates how to provision a basic single-zone OCP VPC cluster along with an additional worker pool attached to the cluster.

The following resources are provisioned by this example:

- A new resource group, if an existing one is not passed in.
- A basic VPC and subnet with public gateway enabled.
- A single zone OCP VPC cluster with a default worker pool.
- An additional worker pool attached to the VPC cluster.
