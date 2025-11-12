#!/bin/bash

set -euo pipefail

echo "🔍 Checking and installing required CLI tools (user-level, no sudo)..."

# # --- Setup local bin directory ---
# LOCAL_BIN="$HOME/bin"
# mkdir -p "$LOCAL_BIN"
# export PATH="$LOCAL_BIN:$PATH"

# # --- Helper to add PATH persistently ---
# if ! grep -q "$LOCAL_BIN" "$HOME/.bashrc"; then
# 	echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >>"$HOME/.bashrc"
# 	echo "✅ Added $LOCAL_BIN to PATH in ~/.bashrc"
# fi

# install_ibm_cli() {
# 	# Simplified installer for IBM Cloud CLI (Linux x86_64 only, no sudo)

# 	host="download.clis.cloud.ibm.com"
# 	metadata_host="$host/ibm-cloud-cli-metadata"
# 	binary_download_host="$host/ibm-cloud-cli"

# 	os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
# 	arch=$(uname -m | tr '[:upper:]' '[:lower:]')

# 	if [ "$os_name" = "linux" ] && echo "$arch" | grep -q 'x86_64'; then
# 		platform="linux64"
# 	else
# 		echo "This installer only supports Linux x86_64 (linux64). Quit installation."
# 		exit 1
# 	fi

# 	# fetch version metadata of CLI
# 	info_endpoint="https://$metadata_host/info.json"
# 	info=$(curl -f -L -s "$info_endpoint")
# 	status="$?"

# 	if [ $status -ne 0 ]; then
# 		echo "Download latest CLI metadata failed. Please check your network connection. Quit installation."
# 		exit 1
# 	fi

# 	# parse latest version from metadata
# 	latest_version=$(echo "$info" | grep -Eo '"latestVersion"[^,]*' | grep -Eo '[^:]*$' | tr -d '"' | tr -d '[:space:]')
# 	if [ -z "$latest_version" ]; then
# 		echo "Unable to parse latest version number. Quit installation."
# 		exit 1
# 	fi

# 	# fetch all versions metadata of CLI
# 	all_versions_endpoint="https://$metadata_host/all_versions.json"
# 	all_versions=$(curl -f -L -s "$all_versions_endpoint")
# 	status="$?"
# 	if [ $status -ne 0 ]; then
# 		echo "Download latest CLI versions metadata failed. Please check your network connection. Quit installation."
# 		exit 1
# 	fi

# 	# extract section of metadata for the desired version
# 	metadata_section=$(echo "$all_versions" | sed -ne '/'\""$latest_version"\"'/,/'"archives"'/p')
# 	if [ -z "$metadata_section" ]; then
# 		echo "Unable to parse metadata for CLI version $latest_version. Quit installation."
# 		exit 1
# 	fi

# 	# get platform-specific binary info
# 	platform_binaries=$(echo "$metadata_section" | sed -ne '/'"$platform"'/,/'"checksum"'/p')

# 	# extract installer URL and checksum
# 	installer_url=$(echo "$platform_binaries" | grep -Eo '"url"[^,]*' | cut -d ":" -f2- | tr -d '"' | tr -d '[:space:]')
# 	sh1sum=$(echo "$platform_binaries" | grep -Eo '"checksum"[^,]*' | cut -d ":" -f2- | tr -d '"' | tr -d '[:space:]')

# 	if [ -z "$installer_url" ] || [ -z "$sh1sum" ]; then
# 		echo "Unable to parse installer URL or checksum. Quit installation."
# 		exit 1
# 	fi

# 	file_name="IBM_Cloud_CLI.tar.gz"
# 	tmp_dir="/tmp/ibmcloud_install"

# 	mkdir -p "$tmp_dir"
# 	echo "Current platform is ${platform}. Downloading IBM Cloud CLI..."

# 	if curl -L "$installer_url" -o "${tmp_dir}/${file_name}"; then
# 		echo "Download complete. Verifying integrity..."
# 	else
# 		echo "Download failed. Please check your network connection. Quit installation."
# 		exit 1
# 	fi

# 	calculated_sha1sum=$(sha1sum "${tmp_dir}/${file_name}" | awk '{print $1}')
# 	if [ "$sh1sum" != "$calculated_sha1sum" ]; then
# 		echo "Downloaded file is corrupted (checksum mismatch). Quit installation."
# 		rm -rf "$tmp_dir"
# 		exit 1
# 	fi

# 	echo "Extracting package..."
# 	tar -xvf "${tmp_dir}/${file_name}" -C "$tmp_dir" >/dev/null 2>&1

# 	if [ ! -x "${tmp_dir}/Bluemix_CLI/install" ]; then
# 		chmod 755 "${tmp_dir}/Bluemix_CLI/install"
# 	fi

# 	echo "Running installer (no sudo)..."
# 	"${tmp_dir}/Bluemix_CLI/install" -q
# 	install_result=$?

# 	rm -rf "${tmp_dir}"

# 	if [ $install_result -eq 0 ]; then
# 		echo "IBM Cloud CLI installation completed successfully."
# 	else
# 		echo "IBM Cloud CLI installation failed."
# 		exit 1
# 	fi

# }

# --- Function to install jq ---
install_jq() {
	echo "Installing jq (locally)..."
	JQ_VERSION="1.7"
	ARCH=$(uname -m)
	OS=$(uname | tr '[:upper:]' '[:lower:]')

	case "$ARCH" in
	x86_64) JQ_ARCH="jq-linux64" ;;
	aarch64) JQ_ARCH="jq-linux64" ;; # same binary works for ARM64 in most cases
	*)
		echo "Unsupported architecture: $ARCH"
		exit 1
		;;
	esac

	curl -L -o "jq" "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/${JQ_ARCH}"
	chmod +x "jq"
	echo "✅ jq installed locally at jq"
}

# --- Check and install kubectl ---
if ! command -v kubectl >/dev/null 2>&1; then
	echo "kubectl not found. Installing latest stable version locally..."
	OS=$(uname | tr '[:upper:]' '[:lower:]')
	KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
	curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${OS}/amd64/kubectl"
	chmod +x ./kubectl
	# mv ./kubectl "kubectl"
	echo "✅ kubectl installed locally at kubectl"
else
	echo "✅ kubectl is already installed. Skipping installation."
fi

# # --- Check and install IBM Cloud CLI ---
# if ! command -v ibmcloud >/dev/null 2>&1; then
# 	echo "IBM Cloud CLI not found. Installing locally..."
# 	install_ibm_cli
# 	echo "✅ IBM Cloud CLI installed locally at $LOCAL_BIN/ibmcloud"
# else
# 	echo "✅ IBM Cloud CLI is already installed. Skipping installation."
# fi

# # --- Ensure IBM Cloud Kubernetes Service CLI plugin ---
# if ! ibmcloud plugin show container-service >/dev/null 2>&1; then
# 	echo "IBM Cloud Kubernetes Service CLI plugin not found. Installing..."
# 	ibmcloud plugin install container-service -f
# 	echo "✅ IBM Cloud Kubernetes Service CLI plugin installed successfully."
# else
# 	echo "✅ IBM Cloud Kubernetes Service CLI plugin is already installed. Skipping installation."
# fi

# # --- Ensure IBM Cloud VPC Infrastructure Service CLI plugin ---
# if ! ibmcloud plugin show is >/dev/null 2>&1; then
# 	echo "IBM Cloud VPC Infrastructure Service CLI plugin not found. Installing..."
# 	ibmcloud plugin install is -f
# 	echo "✅ IBM Cloud VPC Infrastructure Service CLI plugin installed successfully."
# else
# 	echo "✅ IBM Cloud VPC Infrastructure Service CLI plugin is already installed. Skipping installation."
# fi

# --- Check and install jq ---
if ! command -v jq >/dev/null 2>&1; then
	install_jq
else
	echo "✅ jq is already installed. Skipping installation."
fi

echo ""
echo "🎉 All required CLI tools are installed locally:"
# echo "   - IBM Cloud CLI"
# echo "   - IBM Cloud Kubernetes Service CLI plugin"
# echo "   - IBM Cloud VPC Infrastructure Service CLI plugin"
echo "   - kubectl"
echo "   - jq"
echo ""


#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$PWD"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "❌ Error: '$TARGET_DIR' is not a directory."
  exit 1
fi

# --- Detect shell config file ---
if [[ -n "${ZSH_VERSION-}" ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -n "${BASH_VERSION-}" ]]; then
  SHELL_RC="$HOME/.bashrc"
else
  # Fallback for unknown shells
  SHELL_RC="$HOME/.bashrc"
fi

# --- Check if already added ---
EXPORT_LINE="export PATH=\$PATH:$TARGET_DIR"

if grep -Fxq "$EXPORT_LINE" "$SHELL_RC"; then
  echo "✅ PATH already includes $TARGET_DIR in $SHELL_RC"
else
  echo "" >> "$SHELL_RC"
  echo "# Added by add-to-path.sh on $(date)" >> "$SHELL_RC"
  echo "$EXPORT_LINE" >> "$SHELL_RC"
  echo "✅ Added $TARGET_DIR to PATH in $SHELL_RC"
fi

# --- Apply change immediately ---
# shellcheck disable=SC1090
source "$SHELL_RC"
echo "🔁 Applied changes. Current PATH:"
echo "$PATH"
