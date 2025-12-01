#!/bin/bash

set -euo pipefail

REGION="$1"
PRIVATE_ENV="$2"
CLUSTER_ENDPOINT="$3"
CLUSTER_ID="$4"
RESOURCE_GROUP_ID="$5"
POLICY="$6"

# The binaries downloaded by the install-binaries script are located in the /tmp directory.
export PATH=$PATH:"/tmp"

get_cloud_endpoint() {
  iam_cloud_endpoint="${IBMCLOUD_IAM_API_ENDPOINT:-"iam.cloud.ibm.com"}"
  IBMCLOUD_IAM_API_ENDPOINT=${iam_cloud_endpoint#https://}

  cs_api_endpoint="${IBMCLOUD_CS_API_ENDPOINT:-"containers.cloud.ibm.com"}"
  cs_api_endpoint=${cs_api_endpoint#https://}
  IBMCLOUD_CS_API_ENDPOINT=${cs_api_endpoint%/global}
}

get_cloud_endpoint

# This is a workaround function added to retrieve a new token, this can be removed once this issue(https://github.com/IBM-Cloud/terraform-provider-ibm/issues/6107) is fixed.
fetch_token() {
  if [ "$IBMCLOUD_IAM_API_ENDPOINT" = "iam.cloud.ibm.com" ]; then
    if [ "$PRIVATE_ENV" = true ]; then
      IAM_URL="https://private.$IBMCLOUD_IAM_API_ENDPOINT/identity/token"
    else
      IAM_URL="https://$IBMCLOUD_IAM_API_ENDPOINT/identity/token"
    fi
  else
    IAM_URL="https://$IBMCLOUD_IAM_API_ENDPOINT/identity/token"
  fi

  token=$(curl -s -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$IAM_API_KEY" -X POST "$IAM_URL") #pragma: allowlist secret
  IAM_TOKEN=$(echo "$token" | jq -r .access_token)
}

fetch_token

# This is a workaround function added to retrieve the CA cert, this can be removed once this issue(https://github.com/IBM-Cloud/terraform-provider-ibm/issues/6068) is fixed.
get_ca_cert() {
  if [ "$IBMCLOUD_CS_API_ENDPOINT" = "containers.cloud.ibm.com" ]; then
    if [ "$PRIVATE_ENV" = true ]; then
      if [ "$CLUSTER_ENDPOINT" == "private" ] || [ "$CLUSTER_ENDPOINT" == "default" ]; then
        WEBHOOK_URL="https://private.$REGION.$IBMCLOUD_CS_API_ENDPOINT/v2/getCACert?cluster=$CLUSTER_ID"
        result=$(curl -s -H "accept: application/json" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X GET "$WEBHOOK_URL")
      elif [ "$CLUSTER_ENDPOINT" == "vpe" ]; then
        WEBHOOK_URL="https://api.$REGION.$IBMCLOUD_CS_API_ENDPOINT/v2/getCACert?cluster=$CLUSTER_ID"
        result=$(curl -s -H "accept: application/json" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X GET "$WEBHOOK_URL")
      fi
    else
      WEBHOOK_URL="https://$IBMCLOUD_CS_API_ENDPOINT/global/v2/getCACert?cluster=$CLUSTER_ID"
      result=$(curl -s -H "accept: application/json" -H "X-Region: $REGION" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X GET "$WEBHOOK_URL")
    fi
  else
    WEBHOOK_URL="https://$IBMCLOUD_CS_API_ENDPOINT/global/v2/getCACert?cluster=$CLUSTER_ID"
    result=$(curl -s -H "accept: application/json" -H "X-Region: $REGION" -H "Authorization: $IAM_TOKEN" -H "X-Auth-Resource-Group: $RESOURCE_GROUP_ID" -X GET "$WEBHOOK_URL")
  fi

  CERTIFICATE_AUTHORITY=$(echo "$result" | jq -r .caCert | base64 -d)
}

get_ca_cert

curl_request() {
  local endpoint=$1
  local data=$2

  if [ "$IBMCLOUD_CS_API_ENDPOINT" = "containers.cloud.ibm.com" ]; then
    if [ "$PRIVATE_ENV" = true ]; then
      if [ "$CLUSTER_ENDPOINT" == "private" ] || [ "$CLUSTER_ENDPOINT" == "default" ]; then
        WEBHOOK_URL="https://private.$REGION.$IBMCLOUD_CS_API_ENDPOINT/$endpoint"
        result=$(curl -i -H "accept: application/json" -H "Authorization: $IAM_TOKEN" -d "$data" -X PUT "$WEBHOOK_URL" 2>/dev/null)
        status_code=$(echo "$result" | head -n 1 | cut -d$' ' -f2)
      elif [ "$CLUSTER_ENDPOINT" == "vpe" ]; then
        WEBHOOK_URL="https://api.$REGION.$IBMCLOUD_CS_API_ENDPOINT/$endpoint"
        result=$(curl -i -H "accept: application/json" -H "Authorization: $IAM_TOKEN" -d "$data" -X PUT "$WEBHOOK_URL" 2>/dev/null)
        status_code=$(echo "$result" | head -n 1 | cut -d$' ' -f2)
      fi
    else
      WEBHOOK_URL="https://$IBMCLOUD_CS_API_ENDPOINT/global/$endpoint"
      result=$(curl -i -H "accept: application/json" -H "X-Region: $REGION" -H "Authorization: $IAM_TOKEN" -d "$data" -X PUT "$WEBHOOK_URL" 2>/dev/null)
      status_code=$(echo "$result" | head -n 1 | cut -d$' ' -f2)
    fi
  else
    WEBHOOK_URL="https://$IBMCLOUD_CS_API_ENDPOINT/global/$endpoint"
    result=$(curl -i -H "accept: application/json" -H "X-Region: $REGION" -H "Authorization: $IAM_TOKEN" -d "$data" -X PUT "$WEBHOOK_URL" 2>/dev/null)
    status_code=$(echo "$result" | head -n 1 | cut -d$' ' -f2)
  fi

  if [ "${status_code}" == "204" ]; then
    echo "$status_code"
  else
    echo "ERROR:: $endpoint FAILED"
    echo "$result"
  fi
}

CERTIFICATE_AUTHORITY=${CERTIFICATE_AUTHORITY//$'\n'/\\n}
CLIENT_CERT=${CLIENT_CERT//$'\n'/\\n}
CLIENT_KEY=${CLIENT_KEY//$'\n'/\\n}

JSON_BODY="{\"auditServer\": \"$AUDIT_SERVER\",\"caCertificate\": \"$CERTIFICATE_AUTHORITY\",\"clientCertificate\": \"$CLIENT_CERT\",\"clientKey\": \"$CLIENT_KEY\",\"policy\": \"$POLICY\"}"

webhook_attempts=1
while true; do
  response=$(curl_request "v1/clusters/$CLUSTER_ID/apiserverconfigs/auditwebhook" "$JSON_BODY")
  echo "Webhook status: $response"
  if [[ "$response" == "204" ]]; then
    echo "webhook set successfully"
    break
  else
    webhook_attempts=$((webhook_attempts + 1))
    if [ $webhook_attempts -ge 10 ]; then
      echo "Webhook status: $response"
      exit 1
    fi
    echo "Sleeping for 30 secs.."
    sleep 30
  fi
  response=""
done
sleep 60

refresh_attempts=1
while true; do
  response2=$(curl_request "v1/logging/$CLUSTER_ID/refresh" "")
  echo "Refresh status: $response2"
  if [[ "$response2" == "204" ]]; then
    echo "Cluster refreshed successfully"
    break
  else
    refresh_attempts=$((refresh_attempts + 1))
    if [ $refresh_attempts -ge 10 ]; then
      echo "Refresh status: $response2"
      exit 1
    fi
    echo "Sleeping for 30 secs.."
    sleep 30
  fi
  response2=""
done
