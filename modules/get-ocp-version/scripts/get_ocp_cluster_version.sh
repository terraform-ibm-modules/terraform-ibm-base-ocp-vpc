#!/bin/bash

## Returns the OCP major.minor version for the given cluster
## Script is designed to be used with Terraform "external" data source
## It always outputs JSON (even on error) so Terraform plan/apply does not break

set -euo pipefail

login(){
    # Login into the IBM Cloud CLI
    echo "[login] Login to IBM Cloud CLI" >&2
    DIR="$(cd "$(dirname "$0")" && pwd)"
    "$DIR"/ibm_cloud_login.sh >/dev/null 2>&1
    echo "[login] Login complete" >&2
}

get_ocp_version(){
    local cluster_name=$1
    echo " Retrieving OCP version for cluster $cluster_name" >&2

    local output
    output=$(ibmcloud oc cluster get -c "$cluster_name" --output json 2>/dev/null || true)

    local version
    version=$(echo "$output" | jq -r '.masterKubeVersion' | cut -d. -f1,2)

    if [[ -z "$version" || "$version" == "null" ]]; then
        echo "Could not retrieve version for cluster $cluster_name" >&2
        version="-1"
    fi

    echo "$version"
}

## Always return JSON even if something fails
handle_error() {
    echo '{"ocp_version": "-1"}'
    exit 0
}

## Parse variables passed from Terraform "query"
## (reads stdin JSON and converts to shell vars)
eval "$(jq -r '@sh "cluster_name=\(.cluster_name) IBMCLOUD_API_KEY=\(.ibmcloud_api_key)"')"
export IBMCLOUD_API_KEY

## Trap all errors after parsing input
trap 'handle_error' ERR

## Login and retrieve version
login
ocp_version=$(get_ocp_version "$cluster_name")

## Return JSON to Terraform
jq -n -r --arg ocp_version "$ocp_version" '{"ocp_version":$ocp_version}'
