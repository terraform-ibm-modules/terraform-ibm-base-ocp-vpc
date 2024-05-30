#!/bin/bash

set -euo pipefail

REGION="$1"
# RESOURCE_GROUP_ID="$2"
LB_ID="$2"
PRIVATE_ENV="$3"
# PRIVATE_ENDPOINT="$5"
API_VERSION="2024-03-01"

# # Expects the environment variable $IBMCLOUD_API_KEY to be set
# if [[ -z "${IBMCLOUD_API_KEY}" ]]; then
#     echo "API key must be set with IBMCLOUD_API_KEY environment variable" >&2
#     exit 1
# fi

if [[ -z "${REGION}" ]]; then
    echo "Region must be passed as first input script argument" >&2
    exit 1
fi

# if [[ -z "${RESOURCE_GROUP_ID}" ]]; then
#     echo "Resource_group_id must be passed as second input script argument" >&2
#     exit 1
# fi

if [[ -z "${PRIVATE_ENV}" ]]; then
    PRIVATE_ENV=false
fi

# Login to ibmcloud with cli
# attempts=1
# if [ "$PRIVATE_ENV" ]; then
#     until ibmcloud login -q -r "us-south" -a private.cloud.ibm.com || [ $attempts -ge 3 ]; do
#         attempts=$((attempts + 1))
#         echo "Error logging in to IBM Cloud CLI..." >&2
#         sleep 5
#     done
#     IAM_TOKEN=$(ibmcloud iam oauth-tokens --output json | jq -r '.iam_token')
# else
#     until ibmcloud login -q -r "${REGION}" -g "${RESOURCE_GROUP_ID}" -a "cloud.ibm.com" || [ $attempts -ge 3 ]; do
#         attempts=$((attempts + 1))
#         echo "Error logging in to IBM Cloud CLI..." >&2
#         sleep 5
#     done
# fi

lb_attempts=1
if [ "$PRIVATE_ENV" ]; then
    URL="https://$REGION.private.iaas.cloud.ibm.com/v1/load_balancers/$LB_ID?version=$API_VERSION&generation=2"
else
    URL="https://$REGION.iaas.cloud.ibm.com/v1/load_balancers/$LB_ID?version=$API_VERSION&generation=2"
fi

while true; do
    STATUS=$(curl -H "Authorization: $IAM_TOKEN" -X GET "$URL" | jq -r '.operating_status')
    echo "Load balancer status: $STATUS"
    if [[ "$STATUS" == "online" ]]; then
        sleep 120
        STATUS=$(curl -H "Authorization: $IAM_TOKEN" -X GET "$URL" | jq -r '.operating_status')
        if [[ "$STATUS" == "online" ]]; then
            break
        fi
    else
        lb_attempts=$((lb_attempts + 1))
        if [ $lb_attempts -ge 10 ]; then
            echo "Load balancer status: $STATUS"
            break
        fi
        echo "Sleeping for 30 secs.."
        sleep 30
    fi
    STATUS=""
done
