#!/bin/bash

set -euo pipefail

echo "🔍 Checking and installing required CLI tools..."

# --- Function to install jq ---
install_jq() {
    echo "Installing jq..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y jq
    elif command -v yum >/dev/null 2>&1; then
        yum install -y jq
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y jq
    elif command -v brew >/dev/null 2>&1; then
        brew install jq
    else
        echo "Error: No supported package manager found. Please install jq manually."
        exit 1
    fi
    echo "✅ jq installed successfully."
}

# --- Check and install kubectl ---
if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl not found. Installing latest stable version..."
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/$(uname | tr '[:upper:]' '[:lower:]')/amd64/kubectl"
    chmod +x ./kubectl
    mv ./kubectl /usr/local/bin/kubectl
    echo "✅ kubectl installed successfully."
else
    echo "✅ kubectl is already installed. Skipping installation."
fi

# --- Check and install IBM Cloud CLI ---
if ! command -v ibmcloud >/dev/null 2>&1; then
    echo "IBM Cloud CLI not found. Installing..."
    curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
    echo "✅ IBM Cloud CLI installed successfully."
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
echo "🎉 All required CLI tools are installed:"
echo "   - IBM Cloud CLI"
echo "   - IBM Cloud Kubernetes Service CLI plugin"
echo "   - IBM Cloud VPC Infrastructure Service CLI plugin"
echo "   - kubectl"
echo "   - jq"
