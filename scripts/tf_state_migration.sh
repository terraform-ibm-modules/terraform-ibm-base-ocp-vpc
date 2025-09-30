#!/usr/bin/env bash
set -euo pipefail

PRG=$(basename -- "${0}")
USAGE="
Usage: ${PRG} [OPTIONS] [DIRECTORY]

Description:
  Automates Terraform state moves for Red Hat OpenShift VPC cluster resources on IBM Cloud.
  It identifies existing cluster resources in your Terraform state, renames them, and optionally
  reverts previous moves based on revert.txt.

Options:
  -d DIR          Path to Terraform project directory (default: current directory)
  --revert        Revert previously moved resources using 'revert.txt'
  -h, --help      Show this help message and exit

Examples:
  ${PRG}
      Runs the script in the current directory and performs state moves.

  ${PRG} -d /path/to/project
      Runs the script on a specific Terraform project directory.

  ${PRG} --revert /path/to/project
      Reverts previously moved resources based on 'revert.txt'.

Notes:
  - This script automatically generates two files:
      moved.txt   → forward move commands
      revert.txt  → reverse commands for rollback
  - 'terraform state mv' operations require Terraform CLI initialized.
  - Terraform automatically creates a backup of the state file whenever 'terraform state mv' is executed.
"

# ---- Global variables ----
TF_DIR="."
REVERT=false
REVERT_FILE="revert.txt"
MOVED_FILE="moved.txt"
SRC_RESOURCE=""

####################################################################################################################
# Print usage
####################################################################################################################
helpFunction() {
    echo "$USAGE"
    exit 0
}

####################################################################################################################
# Parse arguments
####################################################################################################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d)
                if [[ -n "${2:-}" && ! "${2:-}" =~ ^- ]]; then
                    TF_DIR="$2"
                    shift 2
                else
                    TF_DIR="."
                    shift 1
                fi
                ;;
            --revert)
                REVERT=true
                shift
                ;;
            --module-path)
                if [[ -n "${2:-}" && ! "${2:-}" =~ ^- ]]; then
                    MODULE_PATH="$2"
                    shift 2
                else
                    echo "Missing value for --module-path"
                    exit 1
                fi
                ;;
            -h|--help)
                helpFunction
                ;;
            *)
                echo "Unknown option: $1"
                helpFunction
                ;;
        esac
    done
}

####################################################################################################################
# Prepare Terraform directory
####################################################################################################################
prepare_tf_dir() {
    echo "Using Terraform directory: $TF_DIR"
    cd "$TF_DIR" || { echo "Cannot cd into $TF_DIR"; exit 1; }
}

####################################################################################################################
# Initialize Terraform if needed
####################################################################################################################
terraform_init() {
    if [ ! -d ".terraform" ]; then
        echo "Initializing Terraform backend..."
        terraform init -input=false
    fi
}

####################################################################################################################
# Detect cluster resources dynamically
####################################################################################################################
detect_cluster_resources() {
    echo "Searching for cluster resources in Terraform state..."

    ALL_RESOURCES=$(terraform state list | grep -E '(^|\.)(ibm_container_vpc_cluster\.[a-zA-Z0-9_]*cluster(\[[0-9]+\])?$)' | grep -v '\.data\.')

    if [ -z "$ALL_RESOURCES" ]; then
        echo "No matching cluster resources found in the state."
        exit 1
    fi

    if [ -n "${MODULE_PATH:-}" ]; then
        echo "Filtering resources by module path (partial/suffix match): $MODULE_PATH"
        FILTERED_RESOURCES=$(echo "$ALL_RESOURCES" | grep "$MODULE_PATH" || true)
        if [ -z "$FILTERED_RESOURCES" ]; then
            echo "No resources found matching module path: $MODULE_PATH"
            exit 1
        fi
        SRC_RESOURCE="$FILTERED_RESOURCES"
    else
        SRC_RESOURCE="$ALL_RESOURCES"
    fi

    echo "Found the following resources:"
    echo "$SRC_RESOURCE"
    echo
}

####################################################################################################################
# Initialize revert/move files
####################################################################################################################
prepare_txt_files() {
    echo "" > "$REVERT_FILE"
    echo "" > "$MOVED_FILE"
}

####################################################################################################################
# Generate and apply state moves
####################################################################################################################
process_state_moves() {
    while IFS= read -r SRC; do
        [ -z "$SRC" ] && continue

        DEST=$(echo "$SRC" | sed -E 's/(^.*ibm_container_vpc_cluster\.[^.]*)(cluster)(\[[0-9]+\])?$/\1cluster_with_upgrade\3/')

        echo "Moving state:"
        echo "FROM: $SRC"
        echo "TO:   $DEST"

        echo "terraform state mv \"$DEST\" \"$SRC\"" >> "$REVERT_FILE"
        echo "terraform state mv \"$SRC\" \"$DEST\"" >> "$MOVED_FILE"

        terraform state mv "$SRC" "$DEST"
        echo
    done <<< "$SRC_RESOURCE"
}

####################################################################################################################
# Perform revert from revert.txt
####################################################################################################################
perform_revert() {
    if [ ! -f "$REVERT_FILE" ]; then
        echo "$REVERT_FILE not found. Cannot revert."
        exit 1
    fi

    echo "Reverting Terraform state..."
    while IFS= read -r CMD; do
        [ -z "$CMD" ] && continue
        echo "$CMD"
        eval "$CMD"
    done < "$REVERT_FILE"

    echo "Running terraform refresh after revert..."
    terraform refresh -input=false
    echo "Revert complete."
}

####################################################################################################################
# Main
####################################################################################################################
main() {
    parse_args "$@"
    prepare_tf_dir
    terraform_init

    if [ "$REVERT" = true ]; then
        perform_revert
    else
        detect_cluster_resources
        prepare_txt_files
        process_state_moves

        echo "State move complete."
        echo "Revert commands saved to: $REVERT_FILE"

        echo "Running terraform refresh..."
        terraform refresh -input=false
    fi
}

main "$@"
