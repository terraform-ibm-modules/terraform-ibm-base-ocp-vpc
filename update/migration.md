# Migrating Terraform State for OpenShift Upgrades

This guide explains how to migrate Terraform state resources during an OpenShift version upgrade on IBM Cloud.
The migration process ensures that existing `ibm_container_vpc_cluster` resources are correctly tracked under new resource addresses without re-creating clusters.

Choose the procedure based on how you deployed your infrastructure.

## Select a procedure

Select the procedure that matches where you deployed the code.

- [Deployed with Schematics](#deployed-with-schematics)
- [Local Terraform](#local-terraform)

## Deployed with Schematics

## Before you begin

Make sure you have recent versions of these command-line prerequisites.

- [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- [IBM Cloud CLI plug-ins](https://cloud.ibm.com/docs/cli?topic=cli-plug-ins):
  - For IBM Schematics deployments: `sch` plug-in (schematics)
- JSON processor `jq` (<https://jqlang.github.io/jq/>)
- [Curl](). To test whether curl is installed on your system, run the following command:

    ```sh
    curl -V
    ```

    If you need to install curl, see <https://everything.curl.dev/install/index.html>.

## Deployed with Schematics

If you deployed your IBM Cloud infrastructure by using Schematics, the `tf_state_migration_schematics.sh` script creates a Schematics job. [View the script](tf_state_migration_schematics.sh).

### Schematics process

1. Set the environment variables:

    1. Set the IBM Cloud API key that has access to your IBM Cloud project or Schematics workspace. Run the following command:

        ```sh
        export IBMCLOUD_API_KEY="<API-KEY>" #pragma: allowlist secret
        ```

        Replace `<API-KEY>` with the value of your API key.

    1. Find your Schematics workspace ID:
        - If you are using IBM Cloud Projects:
            1. Go to [Projects](https://cloud.ibm.com/projects)
            1. Select the project that is associated with your Openshift Cluster deployment.
            1. Click the **Configurations** tab.
            1. Click the configuration name that is associated with your Openshift Cluster deployment.
            1. Under **Workspace** copy the ID.

        - If you are not using IBM Cloud Projects:
            1. Go to [Schematics Workspaces](https://cloud.ibm.com/schematics/workspaces)
            1. Select the location that the workspace is in.
            1. Select the workspace associated with your Openshift Cluster deployment.
            1. Click **Settings**.
            1. Copy the **Workspace ID**.

    1. Run the following command to set the workspace ID as an environment variable:

        ```sh
        export WORKSPACE_ID="<workspace-id>"
        ```

1. Download the script by running this Curl command:

    ```sh
    curl https://raw.githubusercontent.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc/main/update/tf_state_migration_schematics.sh > tf_state_migration_schematics.sh
    ```

1. Run the script:

    ```sh
    bash tf_state_migration_schematics.sh
    ```

    The script creates a job in the Schematics workspace.

1. Monitor the status of the job by selecting the workspace from your [Schematics workspaces dashboard](https://cloud.ibm.com/schematics/workspaces).
    - When the job completes successfully, go to the next step.
    - If the job fails, [create a support cases](https://cloud.ibm.com/docs/get-support?topic=get-support-open-case&interface=ui).

### Apply the changes in Schematics

**⚠️ Warning:** Before you click **Generate plan**, make sure to set `enable_openshift_version_upgrade` to `true`. Failing to do so may cause your migration to fail or result in unexpected state changes.

1. Click **Generate plan** and make sure none of the Clusters will be re-created.
    No resources should be set to be destroyed or re-created.
1. Click **Apply plan**.

### Revert Schematics Changes

Once the resources have been successfully moved, you can undo the changes by running the script again with the `-z` option.

```sh
bash tf_state_migration_schematics.sh -z
```

- If you ran the job in Schematics, a new workspace job reverts the state to what existed before you ran the script initially.
- Make sure to set `enable_openshift_version_upgrade` to `false` before running **Generate plan** so that it doesn't result in any unexpected change.

:exclamation: **Important:** After you revert the changes, don't run any other steps in this process. Create an IBM Cloud support case and include information about the script and errors. For more information, see [Creating support cases](https://cloud.ibm.com/docs/get-support?topic=get-support-open-case&interface=ui).

## Local Terraform

Using `tf_state_migration.sh` to perform Terraform state moves allows Terraform to map an existing cluster to a new resource variant.

This document explains how to migrate Terraform state resources when `enable_openshift_version_upgrade` is set to `true` during an OpenShift version upgrade.

The script:

- Locates existing `ibm_container_vpc_cluster` resources in the Terraform state.
- Updates their addresses to retain the same remote object while tracking it under a new resource instance address.
- Modifies only the **state**, not your `.tf` files.
- Supports selective targeting using module paths.
- Generates a `revert.txt` file to restore the previous state if needed.

After each operation (move or revert), the script runs `terraform refresh` to synchronize the state.

## Generated Files

After migration, you'll see:

| File         | Purpose                          |
| ------------ | -------------------------------- |
| `moved.txt`  | Commands used for forward migration |
| `revert.txt` | Commands used to undo migration  |

Terraform automatically backs up the state file during every `terraform state mv`.

---

## Before you begin

Before running the script:

- Terraform CLI must be installed
- Terraform state initialized (or script will auto-init)
- Run the script **from a directory containing a Terraform configuration** or pass a directory explicitly

---

## Migration

To run the script in the **current directory**, use:

```bash
./tf_state_migration.sh
```

### Specify a Directory

To run the script in a **specific directory**, use:

```bash
./tf_state_migration.sh -d /path/to/terraform/project
```

### Revert Changes

```bash
./tf_state_migration.sh --revert -d /path/to/terraform/project
```

### Show Help

```bash
./tf_state_migration.sh --help
```

| Option           | Description |
|------------------|-------------|
| `-d DIR`         | Run the script in the specified Terraform directory (default: `.`) |
| `--module-path X`| Filter resources using partial/suffix match on module path |
| `--revert`       | Undo previous renames using `revert.txt` |
| `-h, --help`     | Show usage information |

---

## Restrict Migration to a Specific Module

This option lets you filter the resources the script processes based on partial or suffix matching of their module paths. If your Terraform state contains multiple clusters across different modules, you may not want to move all of them. This flag helps you target only specific resources.

### Example state entries

```
module.dev.ibm_container_vpc_cluster.openshift_cluster[0]
module.prod.ibm_container_vpc_cluster.openshift_cluster[0]
```

Example:

```bash
./tf_state_migration.sh --module-path "module.prod"
```

---

## Verify the Migration

You can verify changes via:

```bash
terraform state list | grep ibm_container_vpc_cluster
```

Example result after migration:

```
module.ocp_base.ibm_container_vpc_cluster.cluster_with_upgrade[0]
```

---

### Clean up

After you complete the `terraform state mv`, you can remove the temporary files that are generated by the script by running this command:

```sh
rm moved.txt revert.txt
```

## Reverting Changes

- Use the `--revert` option to undo previously renamed Terraform state resources.
- The script relies on the `revert.txt` file (generated during the forward move) to run the reverse `terraform state mv` commands.
- After reverting, the script automatically runs `terraform refresh -input=false` to synchronize the state.
- **Before reverting, ensure that `enable_openshift_version_upgrade` is set to `false` in your Terraform configuration** to avoid unexpected behavior.
- The `revert.txt` file must be present, and the renamed resources must still exist in the state for the revert to work correctly.
