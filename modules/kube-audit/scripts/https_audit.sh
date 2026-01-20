#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=$1
DEPLOYMENT=$2
SERVICE="${DEPLOYMENT}-service"
CSR_NAME="${SERVICE}.${NAMESPACE}"
SECRET_NAME=${3:-"audit-webhook"}
# The binaries downloaded by the install-binaries script are located in the /tmp directory.
export PATH=$PATH:${4:-"/tmp"}

function check_kubectl_cli() {
    if ! command -v kubectl &>/dev/null; then
        echo "Error: kubectl is not installed. Exiting."
        exit 1
    fi
}

check_kubectl_cli

echo "Waiting for Service ClusterIP..."
cluster_ip=$(
    kubectl wait \
        --for jsonpath='{.spec.clusterIP}' \
        --namespace "${NAMESPACE}" \
        --output jsonpath='{.spec.clusterIP}' \
        --timeout 5m \
        svc/"${SERVICE}"
)

echo "Cluster IP detected: ${cluster_ip}"

function sign_certificate() {
    echo "Generating private key..."
    SERVER_KEY="$(openssl genrsa 4096)"

    echo "Generating CSR..."
    SERVER_CSR="$(
        openssl req -new \
            -key <(printf '%s\n' "${SERVER_KEY}") \
            -config <(
                cat <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
CN = system:node:${SERVICE}.${NAMESPACE}.svc
O = system:nodes

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${SERVICE}.${NAMESPACE}.svc.cluster.local
DNS.2 = ${SERVICE}.${NAMESPACE}.svc
IP.1 = ${cluster_ip}
EOF
            )
    )"

    echo "Submitting Kubernetes CSR..."
    kubectl apply -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  request: $(printf '%s' "${SERVER_CSR}" | base64 | tr -d '\n')
  signerName: kubernetes.io/kubelet-serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

    echo "Approving CSR..."
    kubectl certificate approve "${CSR_NAME}"

    echo "Waiting for signed certificate..."
    kubectl wait \
        --for jsonpath='{.status.certificate}' \
        --timeout 5m \
        csr/"${CSR_NAME}"

    SERVER_CERT="$(
        kubectl get csr/"${CSR_NAME}" \
            -o jsonpath='{.status.certificate}' | base64 --decode
    )"
}

sign_certificate

echo "Creating or replacing TLS secret..."
kubectl delete secret "${SECRET_NAME}" \
    --namespace "${NAMESPACE}" \
    --ignore-not-found

kubectl create secret tls "${SECRET_NAME}" \
    --namespace "${NAMESPACE}" \
    --cert <(printf '%s\n' "${SERVER_CERT}") \
    --key <(printf '%s\n' "${SERVER_KEY}")

echo "Restarting deployment..."
kubectl rollout restart \
    --namespace "${NAMESPACE}" \
    deploy/"${DEPLOYMENT}"

echo "Waiting for rollout to complete..."
kubectl rollout status \
    --timeout 1m \
    --namespace "${NAMESPACE}" \
    deploy/"${DEPLOYMENT}"
