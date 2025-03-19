# Basic single zone cluster with allowed outbound traffic

A simple example that shows how to provision a basic single zone OCP VPC cluster. Also the outbound traffic is allowed, which is required for accessing the Operator Hub.

The following resources are provisioned by this example:

- A new resource group, if an existing one is not passed in.
- A basic VPC and subnet with public gateway enabled.
- A single zone OCP VPC cluster.
