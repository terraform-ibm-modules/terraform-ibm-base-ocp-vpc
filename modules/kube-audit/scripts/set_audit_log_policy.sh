#!/bin/bash

set -euo pipefail

AUDIT_POLICY="$1"

# The binaries downloaded by the install-binaries script are located in the /tmp directory.
export PATH=$PATH:"/tmp"

STORAGE_PROFILE="kubectl patch apiserver cluster --type='merge' -p '{\"spec\":{\"audit\":{\"profile\":\"$AUDIT_POLICY\"}}}'"
MAX_ATTEMPTS=10
RETRY_WAIT=5

function check_kubectl_cli() {
    if ! command -v kubectl &>/dev/null; then
        echo "Error: kubectl is not installed. Exiting."
        exit 1
    fi
}

function apply_kubectl_patch() {

    local attempt=0
    while [ $attempt -lt $MAX_ATTEMPTS ]; do
        echo "Attempt $((attempt + 1)) of $MAX_ATTEMPTS: Applying OpenShift Console patch..."

        if eval "$STORAGE_PROFILE"; then
            echo "Patch applied successfully."
            return 0
        else
            echo "Failed to apply patch. Retrying in ${RETRY_WAIT}s..."
            sleep $RETRY_WAIT
            attempt=$((attempt+1))
            RETRY_WAIT=$((RETRY_WAIT * 2))
        fi
    done

    echo "Maximum retry attempts reached. Could not apply patch."
    exit 1
}

echo "========================================="

check_kubectl_cli
apply_kubectl_patch
sleep 30
echo "========================================="
