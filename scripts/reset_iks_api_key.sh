#!/bin/bash

set -euo pipefail

REGION="$1"
RESOURCE_GROUP_ID="$2"
APIKEY_KEY_NAME="containers-kubernetes-key"
PRIVATE_ENV="$3"

if [[ -z "${REGION}" ]]; then
    echo "Region must be passed as first input script argument" >&2
    exit 1
fi

if [[ -z "${RESOURCE_GROUP_ID}" ]]; then
    echo "Resource_group_id must be passed as second input script argument" >&2
    exit 1
fi

if [ "$PRIVATE_ENV" = true ]; then
    IAM_URL="https://private.iam.cloud.ibm.com/v1/apikeys?account_id=$ACCOUNT_ID&scope=account&pagesize=100&type=user&sort=name"
else
    IAM_URL="https://iam.cloud.ibm.com/v1/apikeys?account_id=$ACCOUNT_ID&scope=account&pagesize=100&type=user&sort=name"
fi

# Initialize an empty JSON array to store the results
apikeys="[]"

# Function to fetch data and handle pagination
fetch_data() {
    local url=$1
    local combined_data="$apikeys"

    while [ "$url" != "null" ]; do
        # echo "Fetching data from: $url"

        # Fetch data from the API
        response=$(curl -s "$url" --header "Authorization: $IAM_TOKEN" --header "Content-Type: application/json")

        # Extract next URL and current data
        next_url=$(echo "$response" | jq -r '.next')
        data=$(echo "$response" | jq -c '.apikeys')

        # Combine current data with previous results
        combined_data=$(echo "$combined_data" | jq -c --argjson data "$data" '. + $data')

        # Update URL to next page
        url=$next_url
    done

    # Update the global apikeys variable
    apikeys=$combined_data

    echo "$apikeys"
}

# run api-key reset command if apikey for given region + resource group does not already exist
reset=true
key_descriptions=()
while IFS='' read -r line; do key_descriptions+=("$line"); done < <(fetch_data "$IAM_URL" | jq -r --arg name "${APIKEY_KEY_NAME}" '.[] | select(.name == $name) | .description')
for i in "${key_descriptions[@]}"; do
    if [[ "$i" =~ ${REGION} ]] && [[ "$i" =~ ${RESOURCE_GROUP_ID} ]]; then
        echo "Found key named ${APIKEY_KEY_NAME} which covers clusters in ${REGION} and resource group ID ${RESOURCE_GROUP_ID}"
        reset=false
        break
    fi
done

if [ "${reset}" == true ]; then
    if [ "$PRIVATE_ENV" = true ]; then
        RESET_URL="https://private.$REGION.containers.cloud.ibm.com/v1/keys"
        curl -H "accept: application/json" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X POST "$RESET_URL"
    else
        RESET_URL="https://containers.cloud.ibm.com/global/v1/keys"
        curl -H "accept: application/json" -H "X-Region: $REGION" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X POST "$RESET_URL" -d ''
    fi
    # sleep for 10 secs to allow the new key to be replicated across backend DB instances before attempting to create cluster
    sleep 10
fi
