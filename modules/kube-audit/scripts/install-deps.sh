#!/bin/bash

set -o errexit
set -o pipefail

ARG=""
DIRECTORY="/tmp"

#######################################
# Feature flags
#######################################

# If true → do not download anything (unless custom URL is used)
DISABLE_EXTERNAL_DOWNLOADS="${DISABLE_EXTERNAL_DOWNLOADS:-false}"

# Optional custom URL prefix for all binaries
CUSTOM_KUBECTL_URL="${CUSTOM_KUBECTL_URL:-}"
CUSTOM_JQ_URL="${CUSTOM_JQ_URL:-}"
CUSTOM_OC_URL="${CUSTOM_OC_URL:-}"

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

	if [[ "$DISABLE_EXTERNAL_DOWNLOADS" == "true" && "$custom_url" != "true" ]]; then
		echo "Downloads disabled (DISABLE_EXTERNAL_DOWNLOADS=true). Skipping $binary."
		return
	fi

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

	BASE_URL="${CUSTOM_KUBECTL_URL:-https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${ARCH}}"

	FILE_NAME="kubectl"

	if [ -n "$CUSTOM_KUBECTL_URL" ]; then
		download "$BINARY" "$KUBECTL_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR" "true"
	else
		download "$BINARY" "$KUBECTL_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR"
	fi

	if [[ ! ("$DISABLE_EXTERNAL_DOWNLOADS" == "true" && -z "$CUSTOM_KUBECTL_URL") ]]; then
		copy_replace_binary "$BINARY" "$TMP_DIR"
		clean "$TMP_DIR"
	fi
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

	BASE_URL="${CUSTOM_JQ_URL:-https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}}"

	FILE_NAME="jq-${JQ_OS}-${ARCH}"

	if [ -n "$CUSTOM_JQ_URL" ]; then
		download "$BINARY" "$JQ_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR" "true"
	else
		download "$BINARY" "$JQ_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR"
	fi

	if [[ ! ("$DISABLE_EXTERNAL_DOWNLOADS" == "true" && -z "$CUSTOM_JQ_URL") ]]; then
		mv "${TMP_DIR}/${FILE_NAME}" "${TMP_DIR}/${BINARY}"
		copy_replace_binary "$BINARY" "$TMP_DIR"
		clean "$TMP_DIR"
	fi
else
	echo "${BINARY} ${JQ_VERSION} already installed - skipping install"
fi

#######################################
# oc
#######################################

OC_OS=${OS}
if [[ $OSTYPE == 'darwin'* ]]; then
	OC_OS="mac"
fi

# OC cli version must be maintained manually, as there is no supported renovate datasource to find newer versions.
OC_VERSION=4.11.9
BINARY=oc

if ! command -v oc >/dev/null 2>&1; then
	FILE_NAME="openshift-client-${OC_OS}-${OC_VERSION}.tar.gz"
	BASE_URL="${CUSTOM_OC_URL:-https://mirror.openshift.com/pub/openshift-v4/${ARCH}/clients/ocp/${OC_VERSION}}"
	TMP_DIR=$(mktemp -d /tmp/${BINARY}-XXXXX)

	echo
	echo "-- Installing ${BINARY} ${OC_VERSION}..."

	if [ -n "$CUSTOM_OC_URL" ]; then
		download "$BINARY" "$OC_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR" "true"
	else
		download "$BINARY" "$OC_VERSION" "$BASE_URL" "$FILE_NAME" "$TMP_DIR"
	fi

	if [[ ! ("$DISABLE_EXTERNAL_DOWNLOADS" == "true" && -z "$CUSTOM_OC_URL") ]]; then
		tar -xzf "${TMP_DIR}/${FILE_NAME}" -C "${TMP_DIR}"
		copy_replace_binary ${BINARY} "${TMP_DIR}"
		clean "${TMP_DIR}"
	fi
else
	echo "${BINARY} cli ${OC_VERSION} already installed - skipping install"
fi
