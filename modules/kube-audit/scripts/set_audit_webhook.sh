#!/bin/bash

set -euo pipefail

REGION="$1"
PRIVATE_ENV="$2"
CLUSTER_ENDPOINT="$3"
CLUSTER_ID="$4"
RESOURCE_GROUP_ID="$5"
POLICY="$6"

# This is a workaround function added to retrive the CA cert, this can be removed once this issue(https://github.com/IBM-Cloud/terraform-provider-ibm/issues/6068) is fixed.
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
        echo "$endpoint successfully executed."
    else
        echo "ERROR:: $endpoint FAILED"
        echo "$result"
        exit 1
    fi
}

get_cloud_endpoint() {
    cs_api_endpoint="${IBMCLOUD_CS_API_ENDPOINT:-"containers.cloud.ibm.com"}"
    cs_api_endpoint=${cs_api_endpoint#https://}
    IBMCLOUD_CS_API_ENDPOINT=${cs_api_endpoint%/global}
}

get_cloud_endpoint

attempts=1
until get_ca_cert || [ $attempts -ge 3 ]; do
    attempts=$((attempts + 1))
    echo "Error getting the CA cert..." >&2
    sleep 60
done

CERTIFICATE_AUTHORITY=${CERTIFICATE_AUTHORITY//$'\n'/\\n}
CLIENT_CERT=${CLIENT_CERT//$'\n'/\\n}
CLIENT_KEY=${CLIENT_KEY//$'\n'/\\n}

JSON_BODY="{\"auditServer\": \"$AUDIT_SERVER\",\"caCertificate\": \"$CERTIFICATE_AUTHORITY\",\"clientCertificate\": \"$CLIENT_CERT\",\"clientKey\": \"$CLIENT_KEY\",\"policy\": \"$POLICY\"}"
response=$(curl_request "v1/clusters/$CLUSTER_ID/apiserverconfigs/auditwebhook" "$JSON_BODY")
echo "$response"
sleep 60

response2=$(curl_request "v1/logging/$CLUSTER_ID/refresh" "")
echo "$response2"
