#!/bin/bash

set -e

# This script is going to delete the ingress certificate secret inside the secret group which
# got created as part of the DA since it is not a good practice to store secrets in
# default group.

secret_group_id=$1
provider_visibility=$2
secrets_manager_instance_id=$3
secrets_manager_region=$4
secrets_manager_endpoint=$5

# decide the iam endpoint depending upon the IBMCLOUD_IAM_API_ENDPOINT env variable set by the user and
# whether provider visibility is public or private
iam_cloud_endpoint="${IBMCLOUD_IAM_API_ENDPOINT:-"iam.cloud.ibm.com"}"
IBMCLOUD_IAM_API_ENDPOINT=${iam_cloud_endpoint#https://}

if [[ "$IBMCLOUD_IAM_API_ENDPOINT" == "iam.cloud.ibm.com" ]]; then
    if [[ "$provider_visibility" == "private" ]]; then
      IBMCLOUD_IAM_API_ENDPOINT="private.${IBMCLOUD_IAM_API_ENDPOINT}"
    fi
fi

# generate iam_token from the ibmcloud_api_key. This will be used to make API requests to secrets manager instance endpoint for fetching and deleting secrets
iam_response=$(curl --retry 3 -s -X POST "https://${IBMCLOUD_IAM_API_ENDPOINT}/identity/token" --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept: application/json' --data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' --data-urlencode "apikey=$API_KEY") # pragma: allowlist secret
error_message=$(echo "${iam_response}" | jq 'has("errorMessage")')

if [[ "${error_message}" != false ]]; then
    echo "${iam_response}" | jq '.errorMessage' >&2
    echo "Could not obtain an IAM access token" >&2
    exit 1
fi
iam_token=$(echo "${iam_response}" | jq -r '.access_token')

# deciding the url of secrets_manager_instance depending upon whether secrets_manager_endpoint is public or private

base_url=https://${secrets_manager_instance_id}
if [[ $secrets_manager_endpoint == "private" ]];then
  base_url="${base_url}.private"
fi
base_url="${base_url}.${secrets_manager_region}.secrets-manager.appdomain.cloud"

# curl command would return the list of secrets, jq is used to fetch length of secrets array in json output and fetching id of secret at particular index
# which will be used while making the DELETE request


json_output=$(curl --fail --retry 3 -s -X GET --location \
  --header "Authorization: Bearer ${iam_token}" \
  --header "Accept: application/json" \
  "${base_url}/api/v2/secrets?groups=$secret_group_id")

secrets_length=$(echo "$json_output" | jq '.secrets | length')

if [[ "$secrets_length" == 0 ]];then
  echo "Found no secrets to delete" >&2
  exit 0
fi

# delete the secrets inside the secret group
# retrycount for deleting a particular secret in case curl command for delete command fails

retryCount=2;
for ((i=0; i<secrets_length; i++)); do

  secret_id=$(echo "$json_output" | jq -r ".secrets[$i].id")
  secret_name=$(echo "$json_output" | jq -r ".secrets[$i].name")
  echo "Deleting secret ${secret_name} with id ${secret_id}" >&2
  for ((j=1; j<=retryCount; j++)); do
    if ! curl --retry 3 -X DELETE --location --header "Authorization: Bearer ${iam_token}" "${base_url}/api/v2/secrets/${secret_id}";then
      if [[ "$j" == "$retryCount" ]];then
        echo "Failed to delete the secret.. please delete manually" >&2
        exit 1
      fi
      echo "Failed to remove the secret.. retrying one more time" >&2
    else
      echo "Successfully deleted the secret" >&2
      break
    fi
  done
done

echo "Waiting for the secrets to be deleted" >&2
sleep 5

secret_count=$(curl --fail --retry 3 -s -X GET --location \
    --header "Authorization: Bearer ${iam_token}" \
    --header "Accept: application/json" \
    "${base_url}/api/v2/secrets?groups=$secret_group_id" | \
  jq '.secrets | length')

if [[ "$secret_count" == 0 ]];then
    echo "successfully deleted all the secrets in the group" >&2
else
    echo "Failed to delete 1 or more secrets.. Please delete manually" >&2
    exit 1
fi
