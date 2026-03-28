# Cluster security group rules example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=base-ocp-vpc-add_rules_to_sg-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/tree/main/examples/add_rules_to_sg">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->

This example will add security rules to the `kube-<vpcid>` and `kube-<clusterId>` security groups.

The following resources are provisioned by this example:

- A new resource group, if an existing one is not passed in.
- A VPC with subnets in a single zone and public gw attached.
- Security rules to the `kube-<vpcid>` and `kube-<clusterId>` security groups.
- A basic single zone OCP VPC cluster.

You may also be interested in the [example](../custom_sg) that attaches separate security groups to worker nodes, as opposed to adding rules to existing IBM managed security groups.
