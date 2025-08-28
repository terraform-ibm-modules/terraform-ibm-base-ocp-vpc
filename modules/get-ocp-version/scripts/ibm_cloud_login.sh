#!/bin/bash

set -euo pipefail

attempts=1
# Expects the environment variable $IBMCLOUD_API_KEY to be set
until ibmcloud login -q --no-region || [ $attempts -ge 3 ]; do
    attempts=$((attempts+1))
    echo "Error logging in to IBM Cloud CLI..." >&2
    sleep 5
done
