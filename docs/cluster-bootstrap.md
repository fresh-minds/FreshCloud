# FreshCloud Cluster Bootstrap (Leaseweb + RKE2)

## Work Item Contract
- Inputs: `docs/architecture-mvp.md`, `AGENTS.md` non-negotiables, Leaseweb VM substrate with private networking, and MVP requirement for reproducible GitOps-ready bootstrap.
- Outputs: A repeatable day-0 bootstrap method, runnable automation under `/scripts/bootstrap`, and objective health verification commands.
- Acceptance Criteria: A new engineer can provision a 3-node Kubernetes cluster from scratch, install baseline add-ons, and confirm the cluster is ready for GitOps deployments.
- How to Verify: Execute the commands in the [Verification](#verification) section on a clean environment and confirm all checks pass.

## Chosen MVP Defaults
- Kubernetes distro: RKE2 (HA, embedded etcd)
- Topology: 3 x RKE2 server nodes (`control-plane + etcd + schedulable worker`)
- CNI: Canal (RKE2 default, production-stable for MVP speed)
- GitOps: Argo CD
- L4 + Ingress: MetalLB (L2 mode) + ingress-nginx
- Storage: Longhorn as default `StorageClass` for dynamic PV provisioning

## Assumptions
- Leaseweb project has three Ubuntu 22.04 LTS VMs on the same private L2 network.
- SSH access is available from the operator machine to all nodes.
- One public IP range is available for MetalLB `LoadBalancer` services.
- Firewall policy allows required Kubernetes/RKE2 traffic between nodes and from admin CIDRs.

## To Verify With Leaseweb
- [ ] Public IP range is usable with MetalLB L2 advertisement on the selected network.
- [ ] Private network provides required L2 adjacency for MetalLB speaker operation.
- [ ] Upstream bandwidth and anti-DDoS profile are sufficient for ingress exposure.
- [ ] Object storage endpoint and credentials are available for Longhorn backup target.

## OS Prerequisites

### 1) Operator Workstation
Install:
- `ansible`, `kubectl`, `helm`, `jq`, `ssh`, `scp`

Minimum versions:
- Ansible 2.14+
- Kubernetes CLI compatible with cluster minor version
- Helm 3.12+

### 2) Cluster Nodes (all 3 VMs)
Required baseline:
- Ubuntu 22.04 LTS
- `open-iscsi`, `nfs-common`, `curl`, `jq`, `iptables`, `socat`, `conntrack`
- Swap disabled
- Kernel modules: `overlay`, `br_netfilter`
- Sysctls:
  - `net.bridge.bridge-nf-call-iptables=1`
  - `net.bridge.bridge-nf-call-ip6tables=1`
  - `net.ipv4.ip_forward=1`

Automation for these prerequisites is included in:
- `/scripts/bootstrap/ansible/rke2-bootstrap.yml`

## Cluster Install Method (RKE2)

### 1) Prepare bootstrap inputs
```bash
cp /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env.example \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env

cp /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/ansible/inventory/hosts.ini.example \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/ansible/inventory/hosts.ini
```

Fill:
- `scripts/bootstrap/bootstrap.env`: token, API host, MetalLB IP pool, Longhorn backup target.
- `scripts/bootstrap/ansible/inventory/hosts.ini`: node IPs and SSH details.

### 2) Bootstrap RKE2 on all nodes
```bash
/Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap-rke2.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/ansible/inventory/hosts.ini
```

This performs:
- OS hardening prerequisites
- RKE2 install on first server node (`cluster-init`)
- Sequential join of remaining server nodes
- Initial node join validation

### 3) Fetch kubeconfig locally
```bash
/Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/configure-kubectl.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env

export KUBECONFIG="${HOME}/.kube/freshcloud.yaml"
```

## CNI Configuration
- Configured in `/etc/rancher/rke2/config.yaml` through Ansible template:
  - `cni: [canal]`
- `rke2-ingress-nginx` is disabled in RKE2 config so ingress is installed in a controlled baseline step.

To switch CNI later:
- Set `RKE2_CNI` in `scripts/bootstrap/bootstrap.env` (supported by RKE2: `canal`, `cilium`, `calico`).
- Re-bootstrap only with a clean cluster rebuild (do not in-place switch CNI on MVP cluster).

## Node Labeling and Taints
MVP policy:
- Labels are mandatory for placement and ownership metadata.
- Control-plane taints are removed (if present) so all 3 nodes remain schedulable in MVP.
- Optional ingress taint is supported but off by default.

Apply baseline labeling/taints:
```bash
/Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/label-and-taint-nodes.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env
```

Optional dedicated ingress taint:
```bash
INGRESS_NODE=cp1 INGRESS_NODE_TAINT='freshcloud.io/ingress=true:NoSchedule' \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/label-and-taint-nodes.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env
```

## Ingress + L4 Load Balancing
Install baseline add-ons:
```bash
/Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/install-addons.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env
```

What it installs:
- MetalLB (`metallb-system`) with:
  - `IPAddressPool` from `METALLB_IP_POOL`
  - `L2Advertisement` for that pool
- ingress-nginx (`ingress-nginx`) with Service type `LoadBalancer`

## Storage Class and PV Strategy
Storage baseline is Longhorn:
- Installed via Helm in `longhorn-system`
- Longhorn class patched as cluster default
- `local-path` default annotation removed (if present)

PV strategy:
- Dynamic provisioning for all stateful workloads via Longhorn `StorageClass`
- Default replica count: `LONGHORN_DEFAULT_REPLICA_COUNT=2` for MVP speed/capacity
- Backups: Longhorn backup target configured to S3-compatible endpoint (`LONGHORN_BACKUP_TARGET`)
- Static PVs are break-glass only and not part of standard deployment path

## GitOps Bootstrap (Argo CD)
Install Argo CD control plane:
```bash
/Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap-argocd.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env
```

If `ARGOCD_ROOT_APP_PATH` points to an existing manifest, the script applies it to start app-of-apps sync.

## End-to-End Bootstrap (One Command)
```bash
/Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap-all.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/ansible/inventory/hosts.ini
```

## Verification

### Automated verification
```bash
/Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/cluster-health.sh
```

### Manual verification commands
```bash
kubectl get nodes -o wide
kubectl -n kube-system get pods
kubectl -n metallb-system get pods
kubectl get ipaddresspools.metallb.io -n metallb-system
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
kubectl get storageclass
kubectl -n longhorn-system get pods
kubectl -n argocd get pods
```

Expected results:
- 3 nodes in `Ready` state
- MetalLB controller/speaker running
- Ingress controller has an external IP from the configured MetalLB pool
- Longhorn `StorageClass` exists and is default
- Argo CD pods are healthy (if Argo bootstrap step was executed)
