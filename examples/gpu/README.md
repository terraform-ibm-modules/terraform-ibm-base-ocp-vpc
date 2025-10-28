# GPU Worker Pool Example

This example illustrates how to create an OpenShift cluster on IBM Cloud VPC with:
1. A default worker pool with basic machines (bx2.4x16) across 3 zones
2. A second worker pool with a single GPU machine (gx3.16x80.l4) in one zone

This configuration is useful for workloads that require both general-purpose compute nodes and specialized GPU nodes for AI/ML workloads.

## Architecture

This example creates:
- A VPC using the landing-zone-vpc module with:
  - Subnets across 3 zones for the default worker pool
  - A separate subnet in zone 1 for the GPU worker pool
  - Public gateways in all 3 zones
- An OpenShift cluster with:
  - Default worker pool: 1 worker per zone (3 total) using bx2.4x16 machines
  - GPU worker pool: 1 worker in zone 1 using gx3.16x80.l4 machine with NVIDIA L4 GPUs

## Usage

```bash
terraform init
terraform plan -var-file="input.tfvars"
terraform apply -var-file="input.tfvars"
```

## Example input.tfvars file

```hcl
ibmcloud_api_key = "your_api_key_here" # pragma: allowlist secret
prefix           = "gpu"
region           = "us-south"
```
