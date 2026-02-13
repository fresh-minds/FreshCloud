# Raspberry Pi 5 Kubernetes Home Server Plan

## Work Item Contract
- Inputs: Goal to run Kubernetes on one Raspberry Pi 5 and access it remotely from outside home.
- Outputs: A phased implementation plan with clear decisions, verification steps, and runbook deliverables.
- Acceptance Criteria: Cluster is reachable remotely, workloads are deployable with GitOps, and backup + restore tests pass for critical data components.
- How to Verify: Complete each work item in sequence and collect evidence from the listed verification checks.

## Assumptions
- Hardware: Raspberry Pi 5 (8 GB+), SSD (USB 3 or NVMe HAT), reliable PSU, and preferably a UPS.
- Network: Home internet with dynamic public IP and no guaranteed static IP.
- Scope: Single-node Kubernetes for MVP (not HA). If you later need HA, add 2 more Pi nodes.
- Access model: Private admin access via Tailscale; optional public app exposure via Cloudflare Tunnel.
- GitOps standard: Flux (lighter footprint than Argo CD for a single Pi).

## Core Decisions
| Area | Decision | Reason |
|---|---|---|
| OS | Ubuntu Server 24.04 LTS (64-bit) | Stable, well-supported on Pi 5, good K3s compatibility. |
| Kubernetes | K3s single-node | Lowest operational overhead for home-hosted cluster. |
| GitOps | Flux | Lightweight and production-sensible for constrained hardware. |
| Private remote access | Tailscale | Works behind NAT/CGNAT without opening router ports. |
| Public app access | Cloudflare Tunnel | Internet reachability without direct inbound ports. |
| Storage baseline | Local SSD + K3s `local-path` | Simple and reliable for single-node MVP. |
| Object storage | MinIO (single-node) | S3-compatible object store for app and backup targets. |
| Database | PostgreSQL (CloudNativePG single instance) | Kubernetes-native operations with managed backup workflows. |
| Observability | Prometheus + Grafana + Loki (resource-limited) | Meets metrics + logs requirement with proven tooling. |
| Secrets | SOPS + age keys | Keep secrets out of Git while staying GitOps-friendly. |

## To Verify Checklist
- [ ] Confirm SSD I/O and power stability under load (no USB power brownouts).
- [ ] Confirm you are behind CGNAT or standard NAT (affects direct port-forward strategy).
- [ ] Confirm domain ownership (needed for friendly remote endpoints).
- [ ] Confirm upload bandwidth and latency are acceptable for your expected traffic.
- [ ] Confirm UPS runtime is sufficient for clean shutdown on power outage.
- [ ] Confirm backup target location (external S3 bucket, NAS, or remote MinIO).

## Work Plan
| ID | Work Item | Inputs | Outputs | Acceptance Criteria | How to Verify |
|---|---|---|---|---|---|
| P-01 | Prepare Pi hardware and base OS | Pi 5, SSD, Ubuntu image | Hardened base host with SSH key auth and static LAN IP | Pi boots from SSD, SSH key-only login works, unattended upgrades enabled | `lsblk`, `hostnamectl`, `ssh -o PasswordAuthentication=no` succeeds |
| P-02 | Host hardening and maintenance baseline | Base OS from P-01 | Firewall, fail2ban, time sync, backup-safe filesystem layout | Only required ports open, logs rotate, automatic security updates active | `ufw status`, `fail2ban-client status`, `timedatectl` |
| P-03 | Private remote admin access | Tailscale account | Secure remote shell from anywhere | You can SSH to Pi over Tailscale IP with no router port forwards | From remote network: `ssh <user>@100.x.y.z` |
| P-04 | Bootstrap K3s and baseline security | Hardened host, static IP | Working single-node cluster with RBAC + default-deny NetworkPolicies | Node is Ready; policy baseline blocks cross-namespace traffic by default | `kubectl get nodes`; run test pod connectivity checks |
| P-05 | Bootstrap Flux GitOps | Git repository and deploy key/token | Cluster reconciles manifests from Git | Flux healthy; Git change auto-syncs to cluster | `flux get all`; commit test manifest and confirm rollout |
| P-06 | Ingress and internet reachability | Domain (optional), Cloudflare account | Remote access paths: private (Tailscale) + public (tunnel) | Public URL resolves and serves selected service over HTTPS | `curl -I https://<public-hostname>` from external network |
| P-07 | Storage + object store baseline | K3s cluster, SSD storage class | MinIO deployed with persistent volume and lifecycle policy | Bucket operations work and data persists through pod restart | `mc ls`, `mc cp`, restart pod, re-check object |
| P-08 | PostgreSQL with backups and restore drill | CNPG manifests, backup target creds | Postgres running with scheduled backups and tested restore | Backup job succeeds and restore reproduces sample dataset | Insert test rows, backup, restore to new DB, compare counts |
| P-09 | Observability stack | Cluster + GitOps | Metrics dashboards, log search, core alerts | Node/pod metrics visible, logs queryable, alert test delivered | Grafana dashboards active; fire synthetic alert and confirm |
| P-10 | Runbooks + day-2 operations | Completed platform from P-01..P-09 | Day-0/day-1/day-2 runbooks and monthly DR cadence | Procedures are executable by another person without tribal knowledge | Execute one full dry-run using only runbook docs |

## Repo Deliverables to Create While Executing
- `docs/runbooks-pi.md` for day-0/day-1/day-2 procedures.
- `docs/pi-to-verify.md` for unresolved assumptions and decisions.
- `infra/k3s/` for bootstrap and cluster baseline manifests.
- `scripts/backup/` for backup and restore test automation.
- `scripts/health/` for daily health checks.

## Execution Sequence
1. Complete `P-01` to `P-03` first so remote access is reliable before Kubernetes changes.
2. Complete `P-04` and `P-05` to make the cluster GitOps-managed early.
3. Complete `P-06` to expose only selected services to the internet.
4. Complete `P-07` and `P-08`, then run backup + restore tests immediately.
5. Complete `P-09` and `P-10` to close operational gaps before production use.
