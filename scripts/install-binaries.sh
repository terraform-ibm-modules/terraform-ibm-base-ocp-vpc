#!/bin/bash

set -o errexit
set -o pipefail

DIRECTORY="/tmp"
JQ_DOWNLOAD_URL=${JQ_DOWNLOAD_URL:-""}
KUBECTL_DOWNLOAD_URL=${KUBECTL_DOWNLOAD_URL:""}
source ./common-bash-library/common/common.sh

install_jq "latest" "${DIRECTORY}" "true" "${JQ_DOWNLOAD_URL}" "true"

install_kubectl "latest" "${DIRECTORY}" "true" "${KUBECTL_DOWNLOAD_URL}" "true"
