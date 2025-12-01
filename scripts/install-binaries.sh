#!/bin/bash

set -o errexit
set -o pipefail

DIRECTORY=${1:-"/tmp"}
# renovate: datasource=github-tags depName=terraform-ibm-modules/common-bash-library
TAG=v0.2.0

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
    --output "${DIRECTORY}/common-bash.tar.gz" \
    "https://github.com/terraform-ibm-modules/common-bash-library/archive/refs/tags/$TAG.tar.gz"

mkdir -p "${DIRECTORY}/common-bash-library"
tar -xzf "${DIRECTORY}/common-bash.tar.gz" --strip-components=1 -C "${DIRECTORY}/common-bash-library"
rm -f "${DIRECTORY}/common-bash.tar.gz"

# TThe file doesn’t exist at the time shellcheck runs, so this check is skipped.
# shellcheck disable=SC1091
source "${DIRECTORY}/common-bash-library/common/common.sh"

echo "Installing jq."
install_jq "latest" "${DIRECTORY}" "true"
echo "Installing kubectl."
install_kubectl "latest" "${DIRECTORY}" "true"

rm -rf "${DIRECTORY}/common-bash-library"

echo "Installation complete successfully"
