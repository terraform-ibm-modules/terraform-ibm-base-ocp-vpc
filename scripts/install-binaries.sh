#!/bin/bash

set -o errexit
set -o pipefail

DIRECTORY="/tmp"
TAG=v0.2.0

echo "Downloading common-bash-library version ${TAG}..!!"
curl -L "https://github.com/terraform-ibm-modules/common-bash-library/archive/refs/tags/$TAG.tar.gz" -o common-bash.tar.gz &>/dev/null
mkdir -p "common-bash-library"
tar -xzf common-bash.tar.gz --strip-components=1 -C "common-bash-library"
rm common-bash.tar.gz

source ./common-bash-library/common/common.sh

echo "Installing jq..!!"
install_jq "latest" "${DIRECTORY}" "true"
echo "Installing kubectl..!!"
install_kubectl "latest" "${DIRECTORY}" "true"

rm -rf common-bash-library
