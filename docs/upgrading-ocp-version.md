# Upgrading OpenShift version using terraform

Consumers who want to deploy an OpenShift cluster through this module and later manage **master** version upgrades via Terraform must set the variable `enable_openshift_version_upgrade` to `true`. Master upgrade typically require manual checks, and potential updates to the workload, therefore this option is set to `false` by default. This is an advanced capability that we recommend to set to `true` only if you have a robust process to handle master upgrades before updating the version via Terraform.

Existing users: this capability was introduced in v3.64 of the module. Existing users with a cluster created on previous version of the module can also enable this variable to manage version upgrades through Terraform. However, when `enable_openshift_version_upgrade` is set to `true`, Terraform may plan to destroy and re-create the cluster because the resource type in the module changes. To prevent this, you **must** migrate the existing state to the new resource address before applying any changes - `ibm_container_vpc_cluster.cluster[0]` to `ibm_container_vpc_cluster.cluster_with_upgrade[0]` or, when using auto-scaling, `ibm_container_vpc_cluster.autoscaling_cluster[0]` to `ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade[0]`. This is a one time migration of the state.

There are several options to do this:

## Use terraform moved blocks (recommended)

The recommended approach is to use Terraform's native `moved` block feature:

```hcl
# Example assuming your OCP module is called "ocp"
moved {
  from = module.ocp.ibm_container_vpc_cluster.cluster[0]
  to   = module.ocp.ibm_container_vpc_cluster.cluster_with_upgrade[0]
}
```

For auto-scaling clusters:
```hcl
moved {
  from = module.ocp.ibm_container_vpc_cluster.autoscaling_cluster[0]
  to   = module.ocp.ibm_container_vpc_cluster.autoscaling_cluster_with_upgrade[0]
}
```

Add this block to your Terraform configuration, run `terraform plan` to verify the state migration, then `terraform apply` to apply the changes. This approach works for both local Terraform and Schematics deployments.

After a successful migration and once all team members have applied the changes, you can safely remove the moved blocks from your configuration.

## Alternative: manual state migration

If you prefer not to use moved blocks, you can manually use the terraform state mv command to migrate resources:

- For local Terraform deployments, see the [terraform state mv documentation](https://developer.hashicorp.com/terraform/cli/commands/state/mv)
- For Schematics deployments, see the [ibmcloud schematics workspace state mv documentation](https://cloud.ibm.com/docs/schematics?topic=schematics-schematics-cli-reference#schematics-wks_statemv)