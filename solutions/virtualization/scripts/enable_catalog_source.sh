#!/bin/bash

set -euo pipefail


PATCH_APPLY="oc patch operatorhub cluster --type json -p '[{\"op\": \"add\", \"path\": \"/spec/disableAllDefaultSources\", \"value\": false}]'"
MAX_ATTEMPTS=10

function check_oc_cli() {
  if ! command -v oc &> /dev/null; then
    echo "Error: OpenShift CLI (oc) is not installed. Exiting."
    exit 1
  fi
}

function apply_oc_patch() {

  local attempt=0
  local retry_wait_time=5

  while [ $attempt -lt $MAX_ATTEMPTS ]; do
    echo "Attempt $((attempt+1)) of $MAX_ATTEMPTS: Applying OpenShift Console patch..."

    if eval "$PATCH_APPLY"; then
      echo "Patch applied successfully."
      return 0
    else
      echo "Failed to apply patch. Retrying in ${retry_wait_time}s..."
      sleep $retry_wait_time
      ((attempt++))
    fi
  done

  echo "Maximum retry attempts reached. Could not apply patch."
  exit 1
}

echo "========================================="

check_oc_cli

    echo "Enabling default catalog source"
    apply_oc_patch

echo "========================================="
