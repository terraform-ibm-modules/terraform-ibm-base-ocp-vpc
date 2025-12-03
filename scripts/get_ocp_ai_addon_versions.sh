#!/bin/bash
set -euo pipefail

#############################################
# Read Input
#############################################

INPUT="$(tee)"
REGION="$(echo "$INPUT" | jq -r '.region // empty')"
IBMCLOUD_API_KEY="$(echo "$INPUT" | jq -r '.ibmcloud_api_key // empty')"

#############################################
# Validate Input
#############################################

if [[ -z "$IBMCLOUD_API_KEY" ]]; then
  echo "Error: IBMCLOUD_API_KEY is required." >&2
  exit 1
fi

if [[ -z "$REGION" ]]; then
  echo "Error: REGION is required." >&2
  exit 1
fi

#############################################
# IBM Cloud Login
#############################################

if ! ibmcloud login --apikey "$IBMCLOUD_API_KEY" -r "$REGION" >&2; then
  echo "Error: Failed to authenticate with IBM Cloud." >&2
  exit 1
fi

#############################################
# Fetch and Extract 'openshift-ai' Add-on Versions
#############################################

OCP_AI_ADDON_VERSION_LIST="$(ibmcloud oc cluster addon versions --output json 2>/dev/null | jq -r '.[] | select(.name == "openshift-ai") | "\(.version) \(.supportedOCPRange)"' || true)"

if [[ -z "$OCP_AI_ADDON_VERSION_LIST" ]]; then
  echo "Error: Failed to retrieve or parse openshift-ai add-on versions." >&2
  exit 1
fi


#############################################
# Convert to JSON Output
#############################################

OUTPUT_JSON="$(echo "$OCP_AI_ADDON_VERSION_LIST" | jq -R -s -c 'split("\n")[:-1] | map(split(" ")) | map({ (.[0]): (.[1] + " " + .[2]) }) | add')"

if [[ -z "$OUTPUT_JSON" ]]; then
  echo "Error: Failed to produce JSON output." >&2
  exit 1
fi

#############################################
# Final Output
#############################################

echo "$OUTPUT_JSON"
