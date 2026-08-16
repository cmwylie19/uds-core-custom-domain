#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_OUT="${ROOT_DIR}/kubeconfig.k0s"

if ! command -v k0s >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://get.k0s.sh | sudo sh
fi

if ! sudo k0s kubectl get nodes -o name >/dev/null 2>&1; then
  sudo mkdir -p /etc/k0s
  sudo cp "${ROOT_DIR}/k0s.yaml" /etc/k0s/k0s.yaml
  sudo k0s install controller --single --config /etc/k0s/k0s.yaml --disable-components=metrics-server --force --start
fi

until sudo k0s kubectl get nodes -o name 2>/dev/null | grep -q '^node/'; do
  sleep 5
done

sudo k0s kubeconfig admin > "${KUBECONFIG_OUT}"
chmod 600 "${KUBECONFIG_OUT}"

export KUBECONFIG="${KUBECONFIG_OUT}"
kubectl wait --for=condition=Ready node --all --timeout=10m

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.32/deploy/local-path-storage.yaml
kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class=true --overwrite
kubectl wait --namespace local-path-storage --for=condition=Available deployment/local-path-provisioner --timeout=5m

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system --for=condition=Available deployment/controller --timeout=5m
kubectl rollout status daemonset/speaker -n metallb-system --timeout=5m
kubectl apply -f "${ROOT_DIR}/metallb-pool.yaml"

kubectl get nodes -o wide
kubectl get storageclass
kubectl get ipaddresspools.metallb.io -n metallb-system -o wide
