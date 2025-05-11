#!/bin/bash

API_KEY=$2

iam_token=$(curl -s -X POST \
  "https://iam.cloud.ibm.com/identity/token" \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --header 'Accept: application/json' \
  --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" \
  --data-urlencode "apikey=$API_KEY" | jq -r '.access_token')


secret_group_id=$1
secrets_manager_crn=$3
secrets_manager_endpoint=$4

secrets_manager_instance_id=$(echo "$secrets_manager_crn" | cut -d ':' -f8)
secrets_manager_region=$(echo "$secrets_manager_crn" | cut -d ':' -f6)
base_url=https://${secrets_manager_instance_id}
if [[ $secrets_manager_endpoint == "private" ]];then 
  base_url="${base_url}.private"
fi
base_url="${base_url}.${secrets_manager_region}.secrets-manager.appdomain.cloud"

http_status=$(curl -s -X GET --location \
    --header "Authorization: Bearer ${iam_token}" \
    --header "Accept: application/json" \
    "${base_url}/api/v2/secrets?groups=$secret_group_id" \
    -o /dev/null -w "%{http_code}")


if [[ $http_status != 200 ]];then 
    echo "Request to list secrets failed with status code " "$http_status"
    echo "exiting the script"
    exit 1
fi


IFS=$'\n' read -r -a secret_ids < <(curl -s -X GET --location \
    --header "Authorization: Bearer ${iam_token}" \
    --header "Accept: application/json" \
    "${base_url}/api/v2/secrets?groups=$secret_group_id" | \
  jq -r '.secrets[]?.id')

unset IFS




for secret_id in "${secret_ids[@]}"; do

  echo "Deleting secret with id " "$secret_id"

  if ! curl -X DELETE --location --header "Authorization: Bearer ${iam_token}" "${base_url}/api/v2/secrets/${secret_id}";then 
    echo "Failed to remove the secret.. retrying one more time"
  else 
    continue
  fi

  if ! curl -X DELETE --location --header "Authorization: Bearer ${iam_token}" "${base_url}/api/v2/secrets/${secret_id}";then 
    echo "Failed to remove the secret.. please delete manually"
    exit 1
  else 
    continue
  fi
done

echo "Waiting for the secrets to be deleted"
sleep 5

secret_count=$(curl -s -X GET --location \
    --header "Authorization: Bearer ${iam_token}" \
    --header "Accept: application/json" \
    "${base_url}/api/v2/secrets?groups=$secret_group_id" | \
  jq '.secrets | length')


if [[ "$secret_count" == 0 ]];then 
    echo "successfully deleted all the secrets in the group.. proceeding with deletion of secret group"
else 
    echo "Failed to delete 1 or more secrets.. Please delete manually"
    exit 1;
fi
