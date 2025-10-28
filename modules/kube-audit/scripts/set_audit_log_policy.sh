#!/bin/bash

set -euo pipefail

AUDIT_POLICY="$1"

STORAGE_PROFILE="oc patch apiserver cluster --type='merge' -p '{\"spec\":{\"audit\":{\"profile\":\"$AUDIT_POLICY\"}}}'"
MAX_ATTEMPTS=10
RETRY_WAIT=10

function check_oc_cli() {
    if ! command -v oc &>/dev/null; then
        echo "Error: OpenShift CLI (oc) is not installed. Exiting."
        exit 1
    fi
}

function apply_oc_patch() {

    local attempt=0
    CURRENT_WAIT=${RETRY_WAIT}
    while [ $attempt -lt $MAX_ATTEMPTS ]; do
        echo "Attempt $((attempt + 1)) of $MAX_ATTEMPTS: Applying OpenShift apiserver patch..."

        if eval "$STORAGE_PROFILE"; then
            echo "Patch applied successfully."
            return 0
        else
            echo "Failed to apply patch. Retrying in ${CURRENT_WAIT}s..."
            sleep $CURRENT_WAIT
            attempt=$((attempt+1))
            CURRENT_WAIT=$((CURRENT_WAIT + RETRY_WAIT))
        fi
    done

    echo "Maximum retry attempts reached. Could not apply patch."
    exit 1
}

echo "========================================="

check_oc_cli
apply_oc_patch
sleep 30
echo "========================================="
