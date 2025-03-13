#!/bin/bash

set -euo pipefail


PATCH_APPLY="oc patch consoles.operator.openshift.io cluster --patch '{\"spec\":{\"managementState\":\"Managed\"}}' --type=merge"
PATCH_REMOVE="oc patch consoles.operator.openshift.io cluster --patch '{\"spec\":{\"managementState\":\"Removed\"}}' --type=merge"
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

function remove_oc_patch() {

  local attempt=0
  local retry_wait_time=5

  while [ $attempt -lt $MAX_ATTEMPTS ]; do
    echo "Attempt $((attempt+1)) of $MAX_ATTEMPTS: Removing OpenShift Console patch..."

    if eval "$PATCH_REMOVE"; then
      echo "Patch removed successfully."
      return 0
    else
      echo "Failed to remove patch. Retrying in ${retry_wait_time}s..."
      sleep $retry_wait_time
      ((attempt++))
    fi
  done

  echo "Maximum retry attempts reached. Could not remove patch."
  exit 1
}

echo "========================================="

if [[ -z "${ENABLE_OCP_CONSOLE:-}" ]]; then
    echo "ENABLE_OCP_CONSOLE must be set ... exiting." >&2
    exit 1
fi

check_oc_cli

if [ "${ENABLE_OCP_CONSOLE}" == "true" ]; then
    echo "Enabling the OpenShift Console"
    apply_oc_patch
else
    echo "Disabling the OpenShift Console"
    remove_oc_patch
fi

echo "========================================="
