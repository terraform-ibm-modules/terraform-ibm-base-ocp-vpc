# 2 MZR clusters in same VPC example

This is an example of creating 2 MZR clusters in same VPC, and deploying the _observability agents_ in the clusters.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A basic VPC and two subnets with two public gateways enabled in 2 zones.
- Two multi zone OCP Clusters.
- One Observability Instance.
- Two Observability Agents.
