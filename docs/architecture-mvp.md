# FreshCloud MVP Architecture (Leaseweb)

## Work Item Contract
- Inputs: `docs/wbs.md` (source of truth), MVP scope from `AGENTS.md`, and Leaseweb provider constraints.
- Outputs: Implementable architecture baseline covering component standards, HA posture, network boundaries, and MVP-vs-next scope.
- Acceptance Criteria: Infra, Kubernetes, and GitOps agents can execute without ambiguous platform decisions; each MVP component has a reason and owner.
- How to Verify: Cross-check each component and boundary below against WBS owners/tasks (`A-*`, `L-*`, `K-*`, `G-*`, `S-*`, `O-*`, `D-*`).

## WBS Alignment
This document is aligned to `docs/wbs.md` tasks `A-01` and `A-02`. If this file conflicts with future WBS updates, update this architecture within the same PR.

## Target State (MVP)
FreshCloud MVP runs in one Leaseweb region on a single 3-node RKE2 cluster (`cp+worker` on each node), with namespace-separated environments (`dev`, `stage`, `prod`) managed by Argo CD.

Terraform provisions Leaseweb network/compute/edge primitives. Ansible bootstraps RKE2 and node hardening. Argo CD deploys all platform workloads from Git. Core stateful services (Postgres and MinIO) run on Longhorn-backed volumes and must pass recurring backup plus restore drills before MVP sign-off.

## Component Standards (MVP)
| Domain | Component | MVP Choice/Standard | Primary Owner | Why It Is In MVP | HA Posture | Backup + Restore Standard |
|---|---|---|---|---|---|---|
| Infrastructure | Leaseweb compute/network edge | Leaseweb VMs, private network, reserved public IP, host firewall baseline via Terraform | Leaseweb Infra Engineer | Required substrate for all higher layers; fully automatable | 3 nodes minimum; tolerate single-node loss | Terraform state + IaC in Git; quarterly rebuild drill from IaC |
| Kubernetes | Cluster distro | RKE2 with embedded etcd on all 3 nodes | Kubernetes Engineer | Production-sensible baseline with lower ops overhead than kubeadm | etcd quorum survives 1 node failure | etcd snapshots daily; tested cluster rebootstrap from GitOps |
| GitOps | Deployment control plane | Argo CD app-of-apps + Kustomize overlays (`dev/stage/prod`) | GitOps Engineer | Single source of truth and controlled promotion | Argo CD controller/server at 2 replicas where feasible | Git history is source of truth; restore by rebootstrap + resync |
| Ingress/TLS | External traffic entry | MetalLB + ingress-nginx + cert-manager (Let's Encrypt) | Kubernetes Engineer | Delivers public HTTPS ingress on non-managed-LB infrastructure | 2 ingress controller replicas + PDB, single VIP endpoint | Ingress config in Git; cert re-issuance tested in staging |
| Storage | Persistent volume layer | Longhorn with `longhorn-standard` (2 replicas) and `longhorn-critical` (3 replicas) classes | Kubernetes Engineer | HA block storage without external SAN dependency | Survives single-node failure for replicated volumes | Longhorn recurring backups to S3 target; monthly restore drill |
| Data | Object storage | MinIO tenant in `data` namespace | Data Services Engineer | S3-compatible object storage is explicit MVP scope | 4 MinIO pods distributed across nodes (erasure-coded) | Daily backup/mirror to backup bucket + monthly object restore test |
| Data | Postgres | CloudNativePG (1 primary + 1 replica minimum) | Data Services Engineer | Managed Postgres operations with PITR support | DB remains available after one pod/node failure | Base backups + continuous WAL archive; monthly PITR drill |
| Observability | Metrics and logs | kube-prometheus-stack + Loki + log shipping | Observability SRE | Required for SLOs, alerting, and incident response | Critical components at >=2 replicas where supported | Retain operational logs/metrics per policy; restore dashboards from Git |
| Security | Baseline controls | RBAC least privilege, PSA, default-deny NetworkPolicies, policy engine admission controls | Security & Compliance | Required minimum security stance before go-live | Controls enforced cluster-wide via GitOps | Audit evidence retained; policy rollback/reapply tested |
| Secrets | Secret management | SOPS (age) for Git-encrypted secret manifests + External Secrets Operator for namespace distribution | GitOps Engineer | Keeps plaintext secrets out of Git while enabling runtime injection | ESO controller deployed with HA replicas | Secret rotation test each sprint; decryption + sync path tested |

## HA Posture (MVP)
### Platform-Level
- Region strategy: single Leaseweb region for MVP (no regional failover in MVP).
- Cluster shape: 3-node RKE2 cluster, all nodes run control-plane + worker roles.
- Failure tolerance target: any single node loss must not cause platform-wide outage.

### Service-Level Availability Targets
| Service | MVP Topology | Failure Tolerance | RTO/RPO Target |
|---|---|---|---|
| Kubernetes control plane | 3-node etcd quorum | 1 node | RTO <= 30 min, RPO <= 15 min |
| Ingress (NGINX) | 2 replicas behind MetalLB VIP | 1 pod/node | RTO <= 15 min, RPO n/a |
| Longhorn volumes | 2-3 replicas based on class | 1 node for replicated volumes | RTO <= 30 min, RPO <= 24 h |
| MinIO | Distributed mode across >=4 pods | 1 pod/node | RTO <= 60 min, RPO <= 24 h |
| CloudNativePG | Primary + replica | 1 pod/node | RTO <= 45 min, RPO <= 15 min |
| GitOps config | Git + Argo resync | Argo pod loss | RTO <= 30 min, RPO ~= 0 (Git) |

## Network Boundaries and Allowed Flows
### Addressing Baseline (Assumed)
- Leaseweb private network CIDR: `10.40.0.0/16` (to verify with Leaseweb).
- RKE2 pod CIDR: `10.42.0.0/16`.
- RKE2 service CIDR: `10.43.0.0/16`.

### Boundaries
| Boundary ID | From -> To | Allowed MVP Flows | Denied/Restricted by Default | Owner |
|---|---|---|---|---|
| B1 Edge | Internet -> Ingress VIP | TCP 80/443 | All other inbound ports | Leaseweb Infra Engineer |
| B2 Admin Plane | Admin CIDRs/VPN -> Node mgmt + K8s API | TCP 22, 6443 (restricted source CIDRs) | Public access to SSH/API | Leaseweb Infra Engineer |
| B3 Node Mesh | Cluster nodes -> cluster nodes | RKE2, CNI, Longhorn internal traffic on private network | Node traffic from public interfaces | Kubernetes Engineer |
| B4 App Ingress | Ingress namespace -> app namespaces | HTTP/HTTPS to declared services only | Direct Internet -> app namespace paths | Kubernetes Engineer |
| B5 App-to-Data | App namespaces -> `data` namespace | Explicit allow-list to Postgres and MinIO service ports | Cross-namespace traffic not explicitly allowed | Security & Compliance |
| B6 Backup Egress | Cluster data components -> backup object storage | TLS egress to approved S3 endpoints | Unrestricted outbound egress | Data Services Engineer |
| B7 GitOps Control | Argo CD -> Git provider | Outbound HTTPS pull only | Inbound webhook dependency (optional, not required) | GitOps Engineer |

### Network Policy Baseline
- All application namespaces start with default-deny ingress and egress.
- Only platform namespaces (`ingress-nginx`, `cert-manager`, `monitoring`) receive explicit cross-namespace policy exceptions.
- Postgres and MinIO accept traffic only from approved namespaces/service accounts.

## MVP vs Next Scope
| Area | MVP (Now) | Next (After MVP) |
|---|---|---|
| Regions and clusters | Single region, single cluster, namespace-separated `dev/stage/prod` | Separate clusters per environment; optional second region for DR |
| Compute model | Leaseweb VMs via Terraform | Evaluate bare metal or mixed nodes based on utilization |
| Ingress and edge | MetalLB + NGINX + cert-manager | Managed/global edge, WAF, advanced DDoS routing |
| Storage | Longhorn replicated volumes | Evaluate external CSI/SAN for higher IOPS and larger scale |
| Postgres | CloudNativePG with 1 replica + PITR backups | Multi-cluster replication and automated failover across regions |
| Object storage | In-cluster MinIO tenant + off-cluster backups | Multi-site MinIO replication or managed object storage primary |
| Observability | Metrics + logs; traces optional | Full distributed tracing and SIEM integration |
| Security | Baseline RBAC/PSA/NP + policy engine | Workload identity federation, stronger attestations, zero-trust segmentation |
| Secrets | SOPS + External Secrets | Dedicated external secret manager with automated rotation workflows |

## Implementation Handoff by Stream
| Stream | Must Implement | Primary Paths |
|---|---|---|
| Leaseweb Infra (`L-*`) | Network, VM, edge IP, firewall, DNS prerequisites | `infra/terraform/leaseweb/*` |
| Kubernetes (`K-*`) | RKE2 bootstrap, Longhorn, ingress/TLS platform stack | `infra/ansible/*`, `gitops/apps/platform/*` |
| GitOps (`G-*`) | Argo bootstrap, overlays, secret workflow/promotion gates | `gitops/bootstrap/*`, `gitops/environments/*`, `.sops.yaml` |
| Data (`D-*`) | MinIO + CNPG deployment, backup/restore automation | `gitops/apps/data/*`, `scripts/restore-tests/*` |
| Security (`S-*`) | Baseline policy and audit controls | `gitops/apps/security/*` |
| Observability (`O-*`) | Metrics/logging stack and SLO dashboards | `gitops/apps/observability/*` |

## To Verify with Leaseweb
- [ ] Confirm reserved/floating IP behavior and failover semantics needed for MetalLB VIP ownership.
- [ ] Confirm whether the target private network supports the required L2/L3 behavior for MetalLB mode.
- [ ] Confirm API coverage for firewall, private networking, and IP operations required by Terraform modules.
- [ ] Confirm object storage service capabilities (S3 API, versioning/object lock, lifecycle, retention controls).
- [ ] Confirm bandwidth/egress pricing for backup traffic to avoid hidden backup cost spikes.
- [ ] Confirm available regions/zones and data residency guarantees relevant to sovereign requirements.
- [ ] Confirm DDoS protections and operational escalation process for volumetric incidents.
- [ ] Confirm snapshot/backup API quotas and restore SLA expectations.
- [ ] Confirm supported hardened OS images and kernel constraints for RKE2 + Longhorn.
- [ ] Confirm DNS automation options (Leaseweb DNS API vs external DNS provider) for cert-manager flows.
