#!/bin/bash

set -euo pipefail

STORAGE_CLASS="$1"

STORAGE_PROFILE="oc patch storageprofile $STORAGE_CLASS -p '{\"spec\": {\"claimPropertySets\": [{\"accessModes\": [\"ReadWriteMany\"], \"volumeMode\": \"Filesystem\"}]}}' --type merge"
MAX_ATTEMPTS=10
RETRY_WAIT=5

function check_oc_cli() {
    if ! command -v oc &>/dev/null; then
        echo "Error: OpenShift CLI (oc) is not installed. Exiting."
        exit 1
    fi
}

function apply_oc_patch() {

    local attempt=0
    while [ $attempt -lt $MAX_ATTEMPTS ]; do
        echo "Attempt $((attempt + 1)) of $MAX_ATTEMPTS: Applying OpenShift Console patch..."

        if eval "$STORAGE_PROFILE"; then
            echo "Patch applied successfully."
            return 0
        else
            echo "Failed to apply patch. Retrying in ${RETRY_WAIT}s..."
            sleep $RETRY_WAIT
            ((attempt++))
            RETRY_WAIT=$((RETRY_WAIT * 2))
        fi
    done

    echo "Maximum retry attempts reached. Could not apply patch."
    exit 1
}

echo "========================================="

check_oc_cli
apply_oc_patch
echo "========================================="
