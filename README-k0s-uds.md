# Host k0s UDS Deployment

This setup uses host-level k0s.

## Network

- Host interface: `wlo1`
- Host address: `192.168.4.90/22`
- MetalLB pool: `192.168.7.240-192.168.7.250`

The pool is inside the host LAN subnet `192.168.4.0/22`, avoids the host IP, and avoids the existing Docker/k3d bridge addresses.

## Run

```sh
./scripts/bootstrap-host-k0s.sh
./scripts/deploy-uds.sh
```

The bootstrap script needs working `sudo` because k0s installs a host system service and writes `/etc/k0s` and `/var/lib/k0s`.

## Post-Deploy Fixes Applied

UDS policy admission blocks the default `local-path` provisioner helper pods unless they are exempted. This repo includes the applied exemption:

```sh
KUBECONFIG=./kubeconfig.k0s kubectl apply -f local-path-uds-exemption.yaml
KUBECONFIG=./kubeconfig.k0s kubectl label namespace local-path-storage zarf.dev/agent=ignore --overwrite
```

The `zarf.dev/agent=ignore` label prevents Zarf from rewriting the helper pod `busybox` image to a local registry image that is not present.

The Keycloak chart uses named PVCs, so after the failed provisioning attempts the missing claims were recreated with:

```sh
KUBECONFIG=./kubeconfig.k0s kubectl apply -f keycloak-pvcs.yaml
```

Current expected Keycloak state:

```sh
KUBECONFIG=./kubeconfig.k0s kubectl get pods,pvc -n keycloak
```

`keycloak-0`, `keycloak-data`, and `keycloak-themes` should all be ready or bound.

## Local Hostname Resolution

The browser needs local host entries for the MetalLB gateway IPs (`/etc/hosts`):

```text
# UDS host-k0s gateways
192.168.7.241 sso.example.com element-web.example.com synapse.example.com mas.example.com mrtc.example.com element-admin.example.com
192.168.7.240 keycloak.admin.example.com
```

Verify:

```sh
getent hosts sso.example.com keycloak.admin.example.com
curl -kI https://sso.example.com/realms/uds/.well-known/openid-configuration
```

The SSO endpoint should return `HTTP/2 200`.

## Custom CA

`uds-config.yaml` sets `CA_BUNDLE_CERTS` from `generated-example-certs/ca.crt` and uses the generated wildcard certificate/key for the tenant and admin gateways:

- `*.example.com`
- `*.admin.example.com`

After deployment, verify the trust bundle with:

```sh
KUBECONFIG=./kubeconfig.k0s kubectl get configmap uds-trust-bundle -A
```

## Reboot Check

This is a host-level k0s install, so the cluster should survive a normal reboot through the k0s system service. After reboot, verify:

```sh
systemctl status k0scontroller
KUBECONFIG=./kubeconfig.k0s kubectl get nodes
KUBECONFIG=./kubeconfig.k0s kubectl get pods -A
curl -kI https://sso.example.com/realms/uds/.well-known/openid-configuration
```

## Create and Deploy Zarf

```bash
uds zarf package create --architecture=amd64 --flavor=upstream . --confirm
uds zarf package deploy ./zarf-package-gov-matrix-amd64-dev-0.0.3-upstream.tar.zst --values deploy-time-values/delta-values.yaml --confirm
```