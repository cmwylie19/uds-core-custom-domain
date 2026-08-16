#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-${ROOT_DIR}/kubeconfig.k0s}"

kubectl config current-context
kubectl get nodes -o wide
kubectl get ipaddresspools.metallb.io -n metallb-system

cd "${ROOT_DIR}"
TLS_CERT="$(base64 -w 0 generated-example-certs/tls.crt)"
TLS_KEY="$(base64 -w 0 generated-example-certs/tls.key)"

uds deploy oci://ghcr.io/defenseunicorns/packages/uds/bundles/k3d-core-demo:1.9.0 \
  --packages core \
  --resume \
  --set ADMIN_TLS_CERT="${TLS_CERT}" \
  --set ADMIN_TLS_KEY="${TLS_KEY}" \
  --set TENANT_TLS_CERT="${TLS_CERT}" \
  --set TENANT_TLS_KEY="${TLS_KEY}" \
  --confirm \
  --no-progress \
  --no-log-file

kubectl get svc -A --field-selector spec.type=LoadBalancer
kubectl get pods -A
