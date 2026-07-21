#!/usr/bin/env bash
#
# Description: Fetches IBM Cloud OCP addon versions from the container-service
#              API and outputs a JSON object for Terraform external data source
#              consumption. Uses curl for native proxy support and retries
#              failed requests with exponential back-off.
#
# Stdin (JSON):
#   IAM_TOKEN  - IBM Cloud IAM bearer token (required)
#   REGION     - IBM Cloud region to query   (required)
#
# Environment:
#   IBMCLOUD_CS_API_ENDPOINT - Override the default API endpoint
#                              (default: https://containers.cloud.ibm.com/global)
#
set -euo pipefail

MAX_RETRIES=5
RETRY_DELAY=2
CURL_TIMEOUT=30

die() {
  echo "[get_ocp_addon_versions] ERROR: $*" >&2
  exit 1
}

# Read and validate JSON input from stdin
input="$(cat)"
IAM_TOKEN="$(printf '%s' "$input" | jq -r '.IAM_TOKEN // empty')"
REGION="$(printf '%s' "$input"    | jq -r '.REGION    // empty')"

[[ -n "$IAM_TOKEN" ]] || die "IAM_TOKEN is required"
[[ -n "$REGION"    ]] || die "REGION is required"

# Resolve API endpoint
API_ENDPOINT="${IBMCLOUD_CS_API_ENDPOINT:-https://containers.cloud.ibm.com/global}"
[[ "$API_ENDPOINT" == https://* ]] || API_ENDPOINT="https://${API_ENDPOINT}"

BASE_PATH="$(printf '%s' "$API_ENDPOINT" | sed 's|https://[^/]*||; s|/*$||')"
[[ -n "$BASE_PATH" ]] || BASE_PATH="/global"

HOST="$(printf '%s' "$API_ENDPOINT" | sed 's|https://||; s|/.*||')"
URL="https://${HOST}${BASE_PATH}/v1/addons"

# Fetch addon list with retry and exponential back-off
body_tmp="$(mktemp)"
trap 'rm -f "$body_tmp"' EXIT

attempt=0
delay=$RETRY_DELAY
raw_response=""

while true; do
  attempt=$(( attempt + 1 ))

  http_status="$(
    curl --silent \
         --show-error \
         --max-time "$CURL_TIMEOUT" \
         --output "$body_tmp" \
         --write-out '%{http_code}' \
         -H "Authorization: Bearer ${IAM_TOKEN}" \
         -H "Accept: application/json" \
         -H "X-Region: ${REGION}" \
         "$URL"
  )" && curl_exit=0 || curl_exit=$?
  body="$(cat "$body_tmp")"

  if [[ $curl_exit -eq 0 && "$http_status" == "200" ]]; then
    raw_response="$body"
    break
  fi

  if [[ $attempt -ge $MAX_RETRIES ]]; then
    die "API request failed after ${MAX_RETRIES} attempts. HTTP status: ${http_status}. Response: ${body}"
  fi

  echo "[get_ocp_addon_versions] Attempt ${attempt} failed (HTTP ${http_status}). Retrying in ${delay}s…" >&2
  sleep "$delay"
  delay=$(( delay * 2 ))
done

# Validate response is a non-empty JSON array
addon_count="$(printf '%s' "$raw_response" | jq 'length' 2>/dev/null)" \
  || die "Response is not valid JSON: ${raw_response}"
[[ "$addon_count" -gt 0 ]] || die "No add-on data found."

# Transform into Terraform external data source format:
# { "<addon_name>": "<json-encoded version map>", … }
output="$(
  printf '%s' "$raw_response" | jq -c '
    group_by(.name) |
    map({
      key: .[0].name,
      value: (
        map({
          key: .version,
          value: {
            supported_openshift_range: (.supportedOCPRange  // "unsupported"),
            supported_kubernetes_range: (.supportedKubeRange // "unsupported")
          }
        }) | from_entries | tojson
      )
    }) |
    from_entries
  '
)"

printf '%s\n' "$output"
