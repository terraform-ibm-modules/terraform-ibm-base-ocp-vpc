# Migration Guide(Openshift version upgrades)

Using `tf_state_migration.sh` to perform terraform state move so terraform can map the existing cluster to a new resource variant

This document explains how to migrate existing Terraform state resources when `enable_openshift_version_upgrade` is passed as true while performing openshift version upgrades.

The script updates the Terraform resources that match:

```
ibm_container_vpc_cluster.<name>cluster
```

to the new resource block:

```
ibm_container_vpc_cluster.<name>cluster_with_upgrade
```

It modifies only the **state**, not your `.tf` files.

It also supports selective targeting using module paths and reverting the changes later using a generated revert.txt file.

After each operation (move or revert), the script runs terraform refresh to sync the state.

## Generated Files

After migration, you'll see:

| File         | Purpose                          |
| ------------ | -------------------------------- |
| `moved.txt`  | Commands used for forward migration |
| `revert.txt` | Commands used to undo migration  |

Terraform automatically backs up the state file during every `terraform state mv`.

---

---

## Before you begin

Before running the script:

* Terraform CLI must be installed
* Terraform state initialized (or script will auto-init)
* Run the script **from a directory containing a Terraform configuration** or pass a directory explicitly

---

## Migration

To run the script in the **current directory**, use:

```bash
./tf_state_migration.sh
```

### Specify a Directory

To preview moves without modifying the state:

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
module.shared.ibm_container_vpc_cluster.shared_cluster
```

Example:

```bash
./tf_state_migration.sh --module-path "module.prod"
```

---

## Post Operation Behaviour

After completion (forward or revert), the script runs:

```bash
terraform refresh -input=false
```

This ensures local state syncs with remote infrastructure.

### Example workflow

```bash
./script.sh -d ~/ocp-tf --module-path "module.dev"
```

### Revert later

```bash
./script.sh --revert -d ~/ocp-tf
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
