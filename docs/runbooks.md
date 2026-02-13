# FreshCloud MVP Runbooks

## Work Item Contract
- Inputs: Architecture decisions, WBS tasks, and sprint readiness goals.
- Outputs: Operational procedures for provisioning, routine operations, upgrades, incidents, and restore testing.
- Acceptance Criteria: Procedures are executable by another engineer without tribal knowledge and include objective verification checks.
- How to Verify: Dry-run each runbook section in staging and capture evidence (command output, dashboards, test artifacts).

## Day-0 Provisioning + Bootstrap
| Step | Inputs | Outputs | Acceptance Criteria | How to Verify |
|---|---|---|---|---|
| D0-1 Provision Leaseweb foundation | Terraform vars, Leaseweb credentials, domain config | VMs, private network, edge IP, firewall rules | 3-node substrate reachable and hardened with least-open ports | `terraform apply` succeeds; SSH reachability only from approved admin CIDRs |
| D0-2 Bootstrap RKE2 cluster | Ansible inventory from D0-1, OS access | Working Kubernetes control plane | All three nodes are `Ready`; core system pods healthy | `kubectl get nodes`; `kubectl -n kube-system get pods` |
| D0-3 Bootstrap Argo CD | Cluster admin context, Git repo access token | GitOps control plane online | Argo CD root app syncs without manual drift edits | Argo UI/CLI shows `Healthy` + `Synced` root app |
| D0-4 Deploy platform baseline | GitOps app manifests | Ingress/TLS, Longhorn, security baseline, observability stack | Public HTTPS endpoint available and storage class default set | `curl https://<domain>` + create PVC and write/read test |
| D0-5 Deploy data services | Longhorn, ingress, secret references, backup bucket | MinIO and Postgres live with scheduled backups | Backup jobs created and first backup completes | Check CronJobs/backup CRs and validate success timestamps |
| D0-6 Go-live smoke and handoff | Endpoints, credentials, runbook checklist | Signed day-0 handoff record | All smoke checks pass and unresolved blockers are documented | Execute `scripts/bootstrap/cluster-health.sh` + record results in sprint report |

## Day-1 Operations
| Routine | Inputs | Outputs | Acceptance Criteria | How to Verify |
|---|---|---|---|---|
| D1-1 Daily platform health check | Grafana dashboards, alert channel, `kubectl` access | Daily health status entry | No critical alert older than SLA; all nodes and core pods healthy | Dashboard review + `kubectl get nodes,pods -A` |
| D1-2 Access management | Joiner/leaver tickets, RBAC policy | Updated access matrix and revoked stale users | Privilege changes applied within SLA and audited | Sample user can only access permitted namespaces/resources |
| D1-3 Backup verification (weekly) | Backup job history, object storage inventory | Backup compliance report | Backup success rate meets SLO (>=99% weekly jobs successful) | Compare scheduled vs successful backup job counts |
| D1-4 Capacity + cost review (weekly) | Resource utilization dashboards, billing export | Rightsizing action list | CPU/memory/storage headroom >=30% for critical services | Utilization report stored and reviewed with owners |
| D1-5 Incident triage | Active alert, logs, metrics, runbook links | Incident timeline and mitigation actions | Incident owner assigned within 10 minutes; status updates every 30 minutes | Check incident ticket timestamps and communication cadence |

## Day-2 Upgrades, Incident Response, Restore Testing
| Procedure | Inputs | Outputs | Acceptance Criteria | How to Verify |
|---|---|---|---|---|
| D2-1 Monthly platform upgrades | Release notes (RKE2, charts), maintenance window | Upgraded cluster/services with rollback point | Upgrade completes without unresolved P1 regressions | Pre/post health checks and rollback test in staging |
| D2-2 Security incident response | Alert/event evidence, audit logs, containment policy | Contained incident with forensic evidence | Compromised identity/workload isolated and root cause documented | Verify network isolation, credential rotation, and audit log integrity |
| D2-3 Restore drill (monthly mandatory) | Latest MinIO/Postgres backups, drill script | Measured RTO/RPO and restored validation data | Two consecutive monthly drills meet RTO/RPO targets | Timed restore logs + checksum/row-count validation |
| D2-4 Post-incident/post-drill improvements | Incident review notes, backlog process | Prioritized corrective actions | High-severity findings have owners and due dates | Track actions in backlog and confirm closure evidence |

## Standard Restore Targets (MVP)
- MinIO object restore: RTO <= 60 minutes, RPO <= 24 hours.
- Postgres PITR restore: RTO <= 45 minutes, RPO <= 15 minutes.
- Platform config restore (GitOps): RTO <= 30 minutes from clean cluster.

## Escalation Matrix (MVP)
- Platform outage (cluster-wide): Kubernetes Engineer primary, Platform Architect secondary.
- Data loss risk: Data Services Engineer primary, Security & Compliance secondary.
- Security breach: Security & Compliance primary, Platform Architect secondary.
- Cost overrun >20% forecast: FinOps primary, Platform Architect secondary.
