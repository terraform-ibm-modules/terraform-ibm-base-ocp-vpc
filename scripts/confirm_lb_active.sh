#!/bin/bash

set -euo pipefail

REGION="$1"
RESOURCE_GROUP_ID="$2"
LB_ID="$3"

# Expects the environment variable $IBMCLOUD_API_KEY to be set
if [[ -z "${IBMCLOUD_API_KEY}" ]]; then
    echo "API key must be set with IBMCLOUD_API_KEY environment variable" >&2
    exit 1
fi

if [[ -z "${REGION}" ]]; then
    echo "Region must be passed as first input script argument" >&2
    exit 1
fi

if [[ -z "${RESOURCE_GROUP_ID}" ]]; then
    echo "Resource_group_id must be passed as second input script argument" >&2
    exit 1
fi

# Login to ibmcloud with cli
attempts=1
until ibmcloud login -q -r "${REGION}" -g "${RESOURCE_GROUP_ID}" || [ $attempts -ge 3 ]; do
    attempts=$((attempts + 1))
    echo "Error logging in to IBM Cloud CLI..." >&2
    sleep 5
done

lb_attempts=1
while true; do
    status=$(ibmcloud is load-balancer "$LB_ID" --output json | jq -r .provisioning_status)
    echo "Load balancer status: $status"
    if [[ "$status" == "active" ]]; then
        break
    else
        lb_attempts=$((lb_attempts + 1))
        if [ $lb_attempts -ge 10 ]; then
            echo "Load balancer status: $status"
            break
        fi
        echo "Sleeping for 30 secs.."
        sleep 30
    fi
    status=""
done
