#!/bin/bash

set -o errexit
set -o pipefail

ARG=""
DIRECTORY="/tmp"

#######################################
# Feature flags
#######################################

# Optional custom URL prefix for all binaries
KUBECTL_DOWNLOAD_URL="${KUBECTL_DOWNLOAD_URL:-}"
JQ_DOWNLOAD_URL="${JQ_DOWNLOAD_URL:-}"

#######################################
# OS / ARCH Detection
#######################################

if [[ $OSTYPE == 'darwin'* ]]; then
  OS="darwin"
  # Detect Apple Silicon vs Intel
  mac_arch="$(sysctl -a 2>/dev/null | grep machdep.cpu.brand_string || true)"
  if [[ "$mac_arch" == 'machdep.cpu.brand_string: Intel'* ]]; then
    ARCH="amd64"
  else
    ARCH="arm64"
  fi
else
  OS="linux"
  ARCH="amd64"
fi

#######################################
# Download helpers
#######################################

function download {
  local binary=$1
  local version=$2
  local url=$3
  local file=$4
  local tmp_dir=$5
  local custom_url=$6

  if [ "$custom_url" = "true" ]; then
    echo "Downloading ${binary}..."
    curl --retry 3 -fLsS "${url}" --output "${tmp_dir}/${file}"
  else
    echo "Downloading ${binary} ${version}..."
    curl --retry 3 -fLsS "${url}/${file}" --output "${tmp_dir}/${file}"
  fi
}

#######################################
# Permission check
#######################################

function permission_check {
  if ! [ -w "${DIRECTORY}" ]; then
    echo "No write permission to ${DIRECTORY}. Using sudo..."
    ARG=sudo
  fi
}

#######################################
# Install to DIRECTORY
#######################################

function copy_replace_binary {
  local binary=$1
  local tmp_dir=$2

  echo "Placing ${binary} into ${DIRECTORY}..."
  permission_check

  ${ARG} rm -f "${DIRECTORY}/${binary}"
  ${ARG} cp -r "${tmp_dir}/${binary}" "${DIRECTORY}"
  ${ARG} chmod +x "${DIRECTORY}/${binary}"
}

#######################################
# Cleanup
#######################################

function clean {
  local tmp_dir=$1
  echo "Deleting tmp dir: ${tmp_dir}"
  rm -rf "${tmp_dir}"
  echo "COMPLETE"
  echo
}

#######################################
# Install: kubectl
#######################################

# renovate: datasource=github-releases depName=kubernetes/kubernetes
KUBECTL_VERSION=v1.34.1
BINARY=kubectl

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found. Installing latest stable version locally..."
  TMP_DIR=$(mktemp -d /tmp/${BINARY}-XXXXX)

  echo
  echo "-- Installing ${BINARY} ${KUBECTL_VERSION}..."

  BASE_URL="${KUBECTL_DOWNLOAD_URL:-https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${ARCH}}"

  FILE_NAME="kubectl"

  if [ -n "$KUBECTL_DOWNLOAD_URL" ]; then
    download "$BINARY" "$KUBECTL_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR" "true"
  else
    download "$BINARY" "$KUBECTL_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR"
  fi

  copy_replace_binary "$BINARY" "$TMP_DIR"
  clean "$TMP_DIR"

else
  echo "${BINARY} ${KUBECTL_VERSION} already installed - skipping install"
fi

#######################################
# Install: jq
#######################################

JQ_OS=${OS}
if [[ $OSTYPE == 'darwin'* ]]; then
  JQ_OS="macos"
fi

# renovate: datasource=github-releases depName=jqlang/jq
JQ_VERSION=1.7.1
BINARY=jq

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found. Installing latest stable version locally..."
  TMP_DIR=$(mktemp -d /tmp/${BINARY}-XXXXX)

  echo
  echo "-- Installing ${BINARY} ${JQ_VERSION}..."

  BASE_URL="${JQ_DOWNLOAD_URL:-https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}}"

  FILE_NAME="jq-${JQ_OS}-${ARCH}"

  if [ -n "$JQ_DOWNLOAD_URL" ]; then
    download "$BINARY" "$JQ_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR" "true"
  else
    download "$BINARY" "$JQ_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR"
  fi

  mv "${TMP_DIR}/${FILE_NAME}" "${TMP_DIR}/${BINARY}"
  copy_replace_binary "$BINARY" "$TMP_DIR"
  clean "$TMP_DIR"

else
  echo "${BINARY} ${JQ_VERSION} already installed - skipping install"
fi
