#!/usr/bin/env bash

PRG=$(basename -- "${0}")
USAGE="
usage: ./${PRG} [-z]

    Required environment variables:
    - IBMCLOUD_API_KEY
    - WORKSPACE_ID

    Dependencies:
    - IBM Cloud CLI
    - IBM Cloud CLI 'schematics' plugin
    - jq
"

REVERT=false

helpFunction() {
    echo ""
    echo "Usage: $0 [-z]"
    echo -e "\t-z [Optional] Flag to revert the changes done to the state file."
    exit 1 # Exit script after printing help
}

# Parse options
while getopts ":z" opt; do
    case "$opt" in
        z) REVERT=true ;;
        \?|*) helpFunction ;;  # Any invalid option triggers help
    esac
done

# Shift parsed options away
shift $((OPTIND -1))

# If anything extra remains, it's an error
if [ $# -gt 0 ]; then
    echo "Error: Unknown argument(s): $*"
    helpFunction
fi

##################################################
# Check Dependencies
##################################################

function dependency_check() {
    dependencies=("ibmcloud" "jq")
    for dependency in "${dependencies[@]}"; do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            echo "\"$dependency\" is not installed. Please install $dependency."
            exit 1
        fi
    done
    plugin_dependencies=("schematics")
    for plugin_dependency in "${plugin_dependencies[@]}"; do
        if ! ibmcloud plugin show "$plugin_dependency" >/dev/null; then
            echo "\"$plugin_dependency\" ibmcloud plugin is not installed. Please install $plugin_dependency."
            exit 1
        fi
    done
    echo "All dependencies are available!"
}

##################################################
# Check Environment Variables
##################################################

# Check that env contains required vars
function verify_required_env_var() {
    printf "\n#### VERIFYING ENV ####\n\n"
    all_env_vars_exist=true
    env_var_array=(IBMCLOUD_API_KEY WORKSPACE_ID)
    set +u
    for var in "${env_var_array[@]}"; do
        [ -z "${!var}" ] && echo "${var} not defined." && all_env_vars_exist=false
    done
    set -u
    if [ ${all_env_vars_exist} == false ]; then
        echo "One or more required environment variables are not defined. Exiting."
        echo "${USAGE}"
        exit 1
    fi
    printf "\nVerification complete\n"
}

##################################################
# IBM Cloud Login
##################################################

# Log in to IBM Cloud using IBMCLOUD_API_KEY env var value
function ibmcloud_login() {
    printf "\n#### IBM CLOUD LOGIN ####\n\n"
    WORKSPACE_REGION=$(echo "$WORKSPACE_ID" | cut -d "." -f 1)
    attempts=1
    until ibmcloud login --apikey "$IBMCLOUD_API_KEY" -r "$WORKSPACE_REGION" || [ $attempts -ge 3 ]; do
        attempts=$((attempts + 1))
        echo "Error logging in to IBM Cloud CLI..."
        sleep 3
    done
    printf "\nLogin complete\n"
}

##################################################
# Get Workspace Details
##################################################

function get_workspace_details() {
    echo "Getting workspace details..."
    template_id="$(ibmcloud schematics workspace get --id "$WORKSPACE_ID" -o json | jq -r .template_data[0].id)"

    echo "Template ID: $template_id"

    echo "Pulling state..."
    OUTPUT="$(ibmcloud schematics state pull --id "$WORKSPACE_ID" --template "$template_id")"
    STATE=${OUTPUT//'OK'/}
}

##################################################
# Computing move resources
##################################################


function move_state_resources() {
  echo "Running ibmcloud schematics workspace state mv commands..."

  echo "$STATE" | jq -c '.resources[] | select(.mode=="managed" and .type=="ibm_container_vpc_cluster")' | while read -r resource; do
    name=$(echo "$resource" | jq -r '.name')
    module=$(echo "$resource" | jq -r '.module // empty')

    if [[ -n "$module" ]]; then
      old_path="${module}.ibm_container_vpc_cluster.${name}[0]"
      new_path="${module}.ibm_container_vpc_cluster.${name}_with_upgrade[0]"
    else
      old_path="ibm_container_vpc_cluster.${name}[0]"
      new_path="ibm_container_vpc_cluster.${name}_with_upgrade[0]"
    fi

    echo "Moving resource: $old_path -> $new_path"
    ibmcloud schematics workspace state mv \
      --id "$WORKSPACE_ID" \
      --source "$old_path" \
      --destination "$new_path"

  done
}

function revert_state_resources() {
  echo "Running ibmcloud schematics workspace state mv commands (revert migration)..."

  echo "$STATE" | jq -c '.resources[] | select(.mode=="managed" and .type=="ibm_container_vpc_cluster")' | while read -r resource; do
    name=$(echo "$resource" | jq -r '.name')
    module=$(echo "$resource" | jq -r '.module // empty')

    # Strip the _with_upgrade suffix if present
    base_name=$(echo "$name" | sed 's/_with_upgrade$//')

    if [[ -n "$module" ]]; then
      old_path="${module}.ibm_container_vpc_cluster.${name}[0]"
      new_path="${module}.ibm_container_vpc_cluster.${base_name}[0]"
    else
      old_path="ibm_container_vpc_cluster.${name}[0]"
      new_path="ibm_container_vpc_cluster.${base_name}[0]"
    fi

    echo "Reverting resource: $old_path -> $new_path"
    ibmcloud schematics workspace state mv \
      --id "$WORKSPACE_ID" \
      --source "$old_path" \
      --destination "$new_path"
  done
}

##################################################
# Main Function
##################################################

function main() {
    dependency_check
    verify_required_env_var
    ibmcloud_login
    get_workspace_details

    if [ "$REVERT" = true ]; then
        revert_state_resources
    else
        move_state_resources
    fi
}

main
