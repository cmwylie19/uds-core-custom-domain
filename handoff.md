# Matrix Playground Handoff

## Original Prompt

- Create a k0s cluster in this repo and deploy UDS based on [this bundle](https://github.com/defenseunicorns/uds-core/tree/main/bundles/k3d-standard)
- create the k0s cluster with the custom CA in `generated-example-certs`, here are the [docs](https://docs.defenseunicorns.com/core/v1-7/how-to-guides/networking/manage-trust-bundles/)

Additional user instruction:

- Make sure the MetalLB load balancer IP addresses are correct.

## Local Repository State

Working directory:

```text
/home/cmwylie19/matrix-playground
```

Files/directories observed:

```text
.agents/
.codex/
.git/
generated-example-certs/
generated-example-certs.tar.gz
prompt.md
```

`git status --short` failed because the directory is not a normal Git worktree from the sandbox view:

```text
fatal: not a git repository (or any of the parent directories): .git
```

## Installed Local Tools

Found:

```text
/usr/sbin/kubectl
/usr/local/bin/uds
/usr/bin/docker
```

Not found in `PATH`:

```text
k0s
k0sctl
```

Versions checked:

```text
uds version: v0.33.0
kubectl client: v1.34.3+k3s1
kustomize: v5.7.1
```

## Docker State

Docker access required escalated permission from the sandbox. After approval, these containers were running:

```text
CONTAINER ID   IMAGE                                              PORTS                                                                                                  NAMES
1ea10b06facd   ghcr.io/k3d-io/k3d-proxy:5.9.0                     0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp, 0.0.0.0:6550->6443/tcp   k3d-uds-serverlb
c90e72e21696   ghcr.io/defenseunicorns/uds-k3d/k3s:v1.35.6-k3s1                                                                                                          k3d-uds-server-0
```

Important implication:

- Host ports `80` and `443` are already bound by the existing `k3d-uds-serverlb` container.
- A new k0s cluster cannot bind host ports `80` and `443` until the existing k3d UDS cluster is stopped/removed, or the k0s setup uses different host ports.

Docker networks observed:

```text
NETWORK ID     NAME      DRIVER    SCOPE
cbff1e1be509   bridge    bridge    local
9e154f0dfd75   host      host      local
4593678f8d56   k3d-uds   bridge    local
22f9d3330ab4   none      null      local
```

Existing `k3d-uds` network details:

```text
Subnet: 172.18.0.0/16
Gateway: 172.18.0.1
k3d-uds-serverlb: 172.18.0.2/16
k3d-uds-server-0: 172.18.0.3/16
```

## MetalLB IP Address Notes

Do not reuse the existing `k3d-uds` container IPs:

```text
172.18.0.2
172.18.0.3
```

For a k0s-in-Docker setup, the correct MetalLB address pool should be derived from the actual Docker network created for the k0s cluster, not copied from k3d documentation or guessed ahead of time.

Recommended approach:

1. Create a dedicated Docker bridge network for k0s, preferably with a known subnet, for example `172.19.0.0/16`, if it does not conflict with existing Docker networks.
2. Assign the k0s node container(s) fixed IPs near the start of that subnet.
3. Reserve a MetalLB range from unused IPs in the same Docker network subnet, excluding gateway and container IPs.

Example if using a new Docker network `k0s-uds` with:

```text
Subnet: 172.19.0.0/16
Gateway: 172.19.0.1
k0s controller: 172.19.0.2
```

Then a valid MetalLB pool would be:

```text
172.19.255.200-172.19.255.250
```

This range is inside `172.19.0.0/16` and avoids the gateway and low-numbered node IPs.

Before finalizing MetalLB, verify with:

```sh
docker network inspect k0s-uds
```

Then configure the MetalLB `IPAddressPool` with a range inside that inspected subnet.

## Upstream Bundle Reference

The requested UDS deployment should be based on:

```text
https://github.com/defenseunicorns/uds-core/tree/main/bundles/k3d-standard
```

The k3d-standard bundle is designed for k3d, so the k0s implementation needs to account for differences in:

- cluster creation
- ingress/load balancer exposure
- MetalLB address pool
- custom CA/trust bundle injection from `generated-example-certs`

## Work Not Completed

The user interrupted before any cluster files or deployment manifests were created.

No k0s cluster was created.
No UDS deployment was run.
No existing Docker containers or networks were changed.
