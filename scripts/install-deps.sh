#!/bin/bash

set -o errexit
set -o pipefail

ARG=""
DIRECTORY="/tmp"

#######################################
# Feature flags
#######################################

# If true → do not download anything
DISABLE_DOWNLOADS="${DISABLE_DOWNLOADS:-false}"

# Optional custom URL prefix for all binaries
CUSTOM_KUBECTL_URL="${CUSTOM_KUBECTL_URL:-}"
CUSTOM_JQ_URL="${CUSTOM_JQ_URL:-}"

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
	local sumfile=$5
	local tmp_dir=$6
	local custom_url=$7

	if [[ "$DISABLE_DOWNLOADS" == "true" ]]; then
		echo "Downloads disabled (DISABLE_DOWNLOADS=true). Skipping $binary."
		return
	fi

	if [ "$custom_url" = "true" ]; then
		echo "Downloading ${binary}..."
		curl --retry 3 -fLsS "${url}" --output "${tmp_dir}/${file}"
	else
		echo "Downloading ${binary} ${version}..."
		curl --retry 3 -fLsS "${url}/${file}" --output "${tmp_dir}/${file}"

		if [[ -n "$sumfile" ]]; then
			curl --retry 3 -fLsS "${url}/${sumfile}" --output "${tmp_dir}/${sumfile}"
		else
			echo "No checksum file passed, skipping verification."
		fi
	fi

}

function verify {
	local file=$1
	local sumfile=$2
	local tmp_dir=$3

	echo "Verifying..."
	local checksum
	checksum=$(grep "${file}" "${tmp_dir}/${sumfile}" | awk '{print $1}')
	echo "${checksum}  ${tmp_dir}/${file}" | ${SHA256_CMD} -c
}

function verify_alternative {
	local file=$1
	local sumfile=$2
	local tmp_dir=$3

	echo "Verifying..."
	local checksum
	checksum=$(cat "${tmp_dir}/${sumfile}")
	echo "${checksum}  ${tmp_dir}/${file}" | ${SHA256_CMD} -c
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
# SHA256 Tool Detection
#######################################

SHA256_CMD=""
if command -v sha256sum &>/dev/null && sha256sum --version 2>&1 | grep -q "GNU coreutils"; then
	SHA256_CMD="sha256sum"
elif command -v gsha256sum &>/dev/null; then
	SHA256_CMD="gsha256sum"
elif command -v shasum &>/dev/null; then
	SHA256_CMD="shasum -a 256"
else
	if [[ "$OS" == "darwin" ]]; then
		echo "-- Installing coreutils..."
		brew install coreutils
		SHA256_CMD="gsha256sum"
	else
		echo "sha256sum must be installed. Exiting."
		exit 1
	fi
fi

echo "Using SHA256 command: ${SHA256_CMD}"

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
	SUMFILE="kubectl.sha256"

	if [ -n "$CUSTOM_KUBECTL_URL" ]; then
		download "$BINARY" "$KUBECTL_VERSION" "$BASE_URL" "$FILE_NAME" "$SUMFILE" "$TMP_DIR" "true"
	else
		download "$BINARY" "$KUBECTL_VERSION" "$BASE_URL" "$FILE_NAME" "$SUMFILE" "$TMP_DIR"
	fi

	if [[ "$DISABLE_DOWNLOADS" != "true" ]]; then
		verify_alternative "$FILE_NAME" "$SUMFILE" "$TMP_DIR"
		copy_replace_binary "$BINARY" "$TMP_DIR"
		clean "$TMP_DIR"
	fi
else
	echo "${BINARY} ${KUBECTL_VERSION} already installed - skipping"
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
	SUMFILE=""

	if [ -n "$CUSTOM_JQ_URL" ]; then
		download "$BINARY" "$JQ_VERSION" "$BASE_URL" "$FILE_NAME" "$SUMFILE" "$TMP_DIR" "true"
	else
		download "$BINARY" "$JQ_VERSION" "$BASE_URL" "$FILE_NAME" "$SUMFILE" "$TMP_DIR"
	fi

	if [[ "$DISABLE_DOWNLOADS" != "true" ]]; then
		mv "${TMP_DIR}/${FILE_NAME}" "${TMP_DIR}/${BINARY}"
		copy_replace_binary "$BINARY" "$TMP_DIR"
		clean "$TMP_DIR"
	fi
else
	echo "${BINARY} ${JQ_VERSION} already installed - skipping"
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
	SUMFILE="sha256sum.txt"
	TMP_DIR=$(mktemp -d /tmp/${BINARY}-XXXXX)

	echo
	echo "-- Installing ${BINARY} ${OC_VERSION}..."

	if [ -n "$CUSTOM_OC_URL" ]; then
		download "$BINARY" "$OC_VERSION" "$BASE_URL" "$FILE_NAME" "$SUMFILE" "$TMP_DIR" "true"
	else
		download "$BINARY" "$OC_VERSION" "$BASE_URL" "$FILE_NAME" "$SUMFILE" "$TMP_DIR"
	fi
	if [[ "$DISABLE_DOWNLOADS" != "true" ]]; then
		verify ${FILE_NAME} ${SUMFILE} "${TMP_DIR}"
		tar -xzf "${TMP_DIR}/${FILE_NAME}" -C "${TMP_DIR}"
		copy_replace_binary ${BINARY} "${TMP_DIR}"
		clean "${TMP_DIR}"
	fi
else
	echo "${BINARY} cli ${OC_VERSION} already installed - skipping install"
fi
