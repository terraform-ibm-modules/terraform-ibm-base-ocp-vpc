#!/bin/bash

CLUSTER_NAME="$1"

# Login with API key
ibmcloud login --apikey "$IBMCLOUD_API_KEY" >/dev/null 2>&1

# Search for the cluster
OUTPUT=$(ibmcloud oc cluster get -c "$CLUSTER_NAME" 2>/dev/null)

# Extract OCP version
OCP_VERSION=$(echo "$OUTPUT" | grep -i "^Version:" | awk '{print $2}' | cut -d. -f1,2)

# If nothing was found, return "0"
if [ -z "$OCP_VERSION" ]; then
  OCP_VERSION="-1"
fi

# Return the OCP version in JSON format
echo "{ \"ocp_version\": \"${OCP_VERSION}\" }"

exit 0
