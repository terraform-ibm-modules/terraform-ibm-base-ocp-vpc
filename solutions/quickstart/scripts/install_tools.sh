#!/bin/bash

set -euo pipefail

echo "🔍 Checking and installing required CLI tools (user-level, no sudo)..."

# --- Setup local bin directory ---
LOCAL_BIN="$HOME/bin"
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

# --- Helper to add PATH persistently ---
if ! grep -q "$LOCAL_BIN" "$HOME/.bashrc"; then
    echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >> "$HOME/.bashrc"
    echo "✅ Added $LOCAL_BIN to PATH in ~/.bashrc"
fi

# --- Function to install jq ---
install_jq() {
    echo "Installing jq (locally)..."
    JQ_VERSION="1.7"
    ARCH=$(uname -m)
    OS=$(uname | tr '[:upper:]' '[:lower:]')

    case "$ARCH" in
        x86_64) JQ_ARCH="jq-linux64" ;;
        aarch64) JQ_ARCH="jq-linux64" ;; # same binary works for ARM64 in most cases
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    curl -L -o "$LOCAL_BIN/jq" "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/${JQ_ARCH}"
    chmod +x "$LOCAL_BIN/jq"
    echo "✅ jq installed locally at $LOCAL_BIN/jq"
}

# --- Check and install kubectl ---
if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl not found. Installing latest stable version locally..."
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${OS}/amd64/kubectl"
    chmod +x ./kubectl
    mv ./kubectl "$LOCAL_BIN/kubectl"
    echo "✅ kubectl installed locally at $LOCAL_BIN/kubectl"
else
    echo "✅ kubectl is already installed. Skipping installation."
fi

# --- Check and install IBM Cloud CLI ---
if ! command -v ibmcloud >/dev/null 2>&1; then
    echo "IBM Cloud CLI not found. Installing locally..."
    curl -fsSL https://clis.cloud.ibm.com/install/linux | sh -s -- --install-location "$LOCAL_BIN"
    echo "✅ IBM Cloud CLI installed locally at $LOCAL_BIN/ibmcloud"
else
    echo "✅ IBM Cloud CLI is already installed. Skipping installation."
fi

# --- Ensure IBM Cloud Kubernetes Service CLI plugin ---
if ! ibmcloud plugin show container-service >/dev/null 2>&1; then
    echo "IBM Cloud Kubernetes Service CLI plugin not found. Installing..."
    ibmcloud plugin install container-service -f
    echo "✅ IBM Cloud Kubernetes Service CLI plugin installed successfully."
else
    echo "✅ IBM Cloud Kubernetes Service CLI plugin is already installed. Skipping installation."
fi

# --- Ensure IBM Cloud VPC Infrastructure Service CLI plugin ---
if ! ibmcloud plugin show is >/dev/null 2>&1; then
    echo "IBM Cloud VPC Infrastructure Service CLI plugin not found. Installing..."
    ibmcloud plugin install is -f
    echo "✅ IBM Cloud VPC Infrastructure Service CLI plugin installed successfully."
else
    echo "✅ IBM Cloud VPC Infrastructure Service CLI plugin is already installed. Skipping installation."
fi

# --- Check and install jq ---
if ! command -v jq >/dev/null 2>&1; then
    install_jq
else
    echo "✅ jq is already installed. Skipping installation."
fi

echo ""
echo "🎉 All required CLI tools are installed locally:"
echo "   - IBM Cloud CLI"
echo "   - IBM Cloud Kubernetes Service CLI plugin"
echo "   - IBM Cloud VPC Infrastructure Service CLI plugin"
echo "   - kubectl"
echo "   - jq"
echo ""
