#!/bin/bash

set -euo pipefail

REGION="$1"
RESOURCE_GROUP_ID="$2"
APIKEY_KEY_NAME="containers-kubernetes-key"
PRIVATE_ENV="$3"
CLUSTER_ENDPOINT="$4"
MAX_ATTEMPTS=10

if [[ -z "${REGION}" ]]; then
    echo "Region must be passed as first input script argument" >&2
    exit 1
fi

if [[ -z "${RESOURCE_GROUP_ID}" ]]; then
    echo "Resource_group_id must be passed as second input script argument" >&2
    exit 1
fi

get_cloud_endpoint() {
    iam_cloud_endpoint="${IBMCLOUD_IAM_API_ENDPOINT:-"iam.cloud.ibm.com"}"
    IBMCLOUD_IAM_API_ENDPOINT=${iam_cloud_endpoint#https://}

    cs_api_endpoint="${IBMCLOUD_CS_API_ENDPOINT:-"containers.cloud.ibm.com"}"
    cs_api_endpoint=${cs_api_endpoint#https://}
    IBMCLOUD_CS_API_ENDPOINT=${cs_api_endpoint%/global}
}

get_cloud_endpoint

if [ "$IBMCLOUD_IAM_API_ENDPOINT" = "iam.cloud.ibm.com" ]; then
    if [ "$PRIVATE_ENV" = true ]; then
        IAM_URL="https://private.$IBMCLOUD_IAM_API_ENDPOINT/v1/apikeys?account_id=$ACCOUNT_ID&scope=account&pagesize=100&type=user&sort=name"
    else
        IAM_URL="https://$IBMCLOUD_IAM_API_ENDPOINT/v1/apikeys?account_id=$ACCOUNT_ID&scope=account&pagesize=100&type=user&sort=name"
    fi
else
    IAM_URL="https://$IBMCLOUD_IAM_API_ENDPOINT/v1/apikeys?account_id=$ACCOUNT_ID&scope=account&pagesize=100&type=user&sort=name"
fi

reset=true

# Function to fetch data and handle pagination
fetch_data() {
    local url="$IAM_URL"

    while [ "$url" != "null" ]; do
        # Fetch data from the API
        IAM_RESPONSE=$(curl -s "$url" --header "Authorization: $IAM_TOKEN" --header "Content-Type: application/json")

        ERROR_MESSAGE=$(echo "${IAM_RESPONSE}" | jq 'has("errors")')
        if [[ "${ERROR_MESSAGE}" != false ]]; then
            echo "${IAM_RESPONSE}" | jq '.errors'
            echo "Could not obtain api keys"
            exit 1
        fi

        next_url=$(echo "${IAM_RESPONSE}" | jq -r '.next')
        key_descriptions=$(echo "$IAM_RESPONSE" | jq -r --arg name "${APIKEY_KEY_NAME}" '.apikeys | .[] | select(.name == $name) | .description')
        for i in "${key_descriptions[@]}"; do
            if [[ "$i" =~ ${REGION} ]] && [[ "$i" =~ ${RESOURCE_GROUP_ID} ]]; then
                echo "Found key named ${APIKEY_KEY_NAME} which covers clusters in ${REGION} and resource group ID ${RESOURCE_GROUP_ID}"
                reset=false
                break
            fi
        done
        url=$next_url
    done
}

fetch_data

attempt=0
retry_wait_time=5

if [ "${reset}" == true ]; then
    while [ $attempt -lt $MAX_ATTEMPTS ]; do
        if [ "$IBMCLOUD_CS_API_ENDPOINT" = "containers.cloud.ibm.com" ]; then
            if [ "$PRIVATE_ENV" = true ]; then
                if [ "$CLUSTER_ENDPOINT" == "private" ] || [ "$CLUSTER_ENDPOINT" == "default" ]; then
                    RESET_URL="https://private.$REGION.$IBMCLOUD_CS_API_ENDPOINT/v1/keys"
                    result=$(curl -i -H "accept: application/json" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X POST "$RESET_URL" 2>/dev/null)
                    status_code=$(echo "$result" | head -n 1 | cut -d$' ' -f2)
                elif [ "$CLUSTER_ENDPOINT" == "vpe" ]; then
                    RESET_URL="https://api.$REGION.$IBMCLOUD_CS_API_ENDPOINT/v1/keys"
                    result=$(curl -i -H "accept: application/json" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X POST "$RESET_URL" 2>/dev/null)
                    status_code=$(echo "$result" | head -n 1 | cut -d$' ' -f2)
                fi
            else
                RESET_URL="https://$IBMCLOUD_CS_API_ENDPOINT/global/v1/keys"
                result=$(curl -i -H "accept: application/json" -H "X-Region: $REGION" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X POST "$RESET_URL" -d '' 2>/dev/null)
                status_code=$(echo "$result" | head -n 1 | cut -d$' ' -f2)
            fi
        else
            RESET_URL="https://$IBMCLOUD_CS_API_ENDPOINT/global/v1/keys"
            result=$(curl -i -H "accept: application/json" -H "X-Region: $REGION" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X POST "$RESET_URL" -d '' 2>/dev/null)
            status_code=$(echo "$result" | head -n 1 | cut -d$' ' -f2)
        fi

        if [ "${status_code}" == "204" ] || [ "${status_code}" == "200" ]; then
            echo "The IAM API key is successfully reset."
            sleep 10
            exit 0
        else
            echo "ERROR:: FAILED TO RESET THE IAM API KEY"
            echo "$result"
            sleep $retry_wait_time
            attempt=$((attempt+1))
        fi
        # sleep for 10 secs to allow the new key to be replicated across backend DB instances before attempting to create cluster
    done
    echo "Maximum retry attempts reached. Could not reset api key."
    exit 1
fi
