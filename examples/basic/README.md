# Basic single zone example

A simple example that shows how to provision a basic single zone OCP VPC cluster.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A basic VPC and subnet with public gateway enabled.
- A single zone OCP VPC cluster.

**Note:** Operator Hub may not be accessible if the variable `disable_outbound_traffic_protection` is set to `false` which is the defalult value. If you want to have this, you can open up the outbound traffic by setting the variable value as `true`.
