#!/bin/bash

set -e

# This script is going to delete the ingress certificate secret inside the secret group which
# got created as part of the DA since it is not a good practice to store secrets in
# default group.

secret_group_id=$1
secrets_manager_instance_id=$2
secrets_manager_region=$3
secrets_manager_endpoint=$4

# deciding the url of secrets_manager_instance depending upon whether secrets_manager_endpoint is public or private

base_url=https://${secrets_manager_instance_id}
if [[ $secrets_manager_endpoint == "private" ]];then
  base_url="${base_url}.private"
fi
base_url="${base_url}.${secrets_manager_region}.secrets-manager.appdomain.cloud"

# generate iam token
iam_token=$(ibmcloud iam oauth-tokens --output json | jq -r '.iam_token')

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
# retrycount for deleting a particular secret incase curl command for delete command fails

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
