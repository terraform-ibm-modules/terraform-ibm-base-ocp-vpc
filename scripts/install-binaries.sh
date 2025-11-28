#!/bin/bash

set -o errexit
set -o pipefail

DIRECTORY="/tmp"
TAG=v2.0.1-rc

curl -L "https://github.com/terraform-ibm-modules/common-bash-library/archive/refs/tags/$TAG.tar.gz" -o repo.tar.gz
mkdir -p "common-bash-library"
tar -xzf repo.tar.gz --strip-components=1 -C "common-bash-library"
rm repo.tar.gz

source ./common-bash-library/common/common.sh

echo "JQ"
install_jq "latest" "${DIRECTORY}" "true"
echo "KUBECTL"
install_kubectl "latest" "${DIRECTORY}" "true"

rm -rf common-bash-library
