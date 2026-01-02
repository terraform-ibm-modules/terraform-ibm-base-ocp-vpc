#!/bin/bash

# This script is stored in the kube-audit module because modules cannot access
# scripts placed in the root module when they are invoked individually.
# Placing it here also avoids duplicating the install-binaries script across modules.

set -o errexit
set -o pipefail

DIRECTORY=${1:-"/tmp"}
# renovate: datasource=github-tags depName=terraform-ibm-modules/common-bash-library
TAG=v0.2.0
# Running multiple Terraform executions on the same environment that share a /tmp directory can lead to conflicts during script execution.
SUFFIX=""
for _ in {1..4}; do
    SUFFIX+=${RANDOM:0:1}
done

echo "Downloading common-bash-library version ${TAG}."

# download common-bash-library
curl --silent \
    --connect-timeout 5 \
    --max-time 10 \
    --retry 3 \
    --retry-delay 2 \
    --retry-connrefused \
    --fail \
    --show-error \
    --location \
    --output "${DIRECTORY}/common-bash-${SUFFIX}.tar.gz" \
    "https://github.com/terraform-ibm-modules/common-bash-library/archive/refs/tags/$TAG.tar.gz"

mkdir -p "${DIRECTORY}/common-bash-library-${SUFFIX}"
tar -xzf "${DIRECTORY}/common-bash-${SUFFIX}.tar.gz" -C "${DIRECTORY}/common-bash-library-${SUFFIX}"
rm -f "${DIRECTORY}/common-bash-${SUFFIX}.tar.gz"

# The file doesn’t exist at the time shellcheck runs, so this check is skipped.
# shellcheck disable=SC1091,SC1090
source "${DIRECTORY}/common-bash-library-${SUFFIX}/common-bash-library-${TAG#v}/common/common.sh"

echo "Installing jq."
install_jq "latest" "${DIRECTORY}" "true"
echo "Installing kubectl."
install_kubectl "latest" "${DIRECTORY}" "true"

rm -rf "${DIRECTORY}/common-bash-library-${SUFFIX}"

echo "Installation complete successfully"
