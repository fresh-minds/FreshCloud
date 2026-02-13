# FreshCloud MVP Observability Stack

## Work Item Contract
- Inputs: FreshCloud MVP architecture (`/docs/architecture-mvp.md`), Argo CD as GitOps standard, Kubernetes-first stack on Leaseweb, and required observability outcomes (metrics, dashboards, logs, alerting, SLOs).
- Outputs: GitOps manifests for Prometheus/Grafana, Loki/Promtail, and high-signal alert rules under `/gitops/apps/observability`; this implementation document.
- Acceptance Criteria: Cluster health and core platform services are visible in Grafana; at least five high-signal alerts exist for API down, node not ready, disk pressure, cert expiry, and backup failure.
- How to Verify:
  1. Apply/sync `/gitops/apps/observability` through Argo CD.
  2. Confirm pods and PVCs in `observability` namespace are healthy.
  3. Confirm Grafana has both default Kubernetes dashboards and `FreshCloud Platform Overview`.
  4. Confirm alert rules exist in Prometheus and fire in controlled failure tests.
  5. Confirm logs from system and app namespaces arrive in Loki.

## Stack Design (MVP)
- Metrics: `kube-prometheus-stack` (Prometheus Operator, Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics).
- Dashboards: Grafana default Kubernetes dashboards plus a custom `FreshCloud Platform Overview` dashboard.
- Logs: Loki (single-binary) + Promtail DaemonSet for Kubernetes node/pod logs.
- Alerting: Prometheus rules feed Alertmanager; severity split (`critical`, `warning`) and runbook-first triage.
- GitOps standard: Argo CD `Application` resources managed by Kustomize under `/gitops/apps/observability`.

## GitOps Manifests Added
- `/gitops/kustomization.yaml`
- `/gitops/apps/kustomization.yaml`
- `/gitops/apps/observability/kustomization.yaml`
- `/gitops/apps/observability/namespace.yaml`
- `/gitops/apps/observability/app-kube-prometheus-stack.yaml`
- `/gitops/apps/observability/app-loki.yaml`
- `/gitops/apps/observability/app-promtail.yaml`
- `/gitops/apps/observability/grafana-dashboard-platform-overview.yaml`

## Metrics and Dashboards
### Prometheus coverage
- Kubernetes control plane and node health from kube-prometheus-stack defaults.
- kube-state-metrics for workload and job state.
- Persistent metric retention configured for 15 days (Longhorn-backed PVC).

### Grafana coverage
- Default dashboards cover cluster/node/pod baselines.
- Custom dashboard `FreshCloud Platform Overview` surfaces:
  - API server availability.
  - Node readiness and disk pressure.
  - Core namespace pod health (`kube-system`, `argocd`, `observability`, `ingress-nginx`).
  - Certificate-expiry risk.
  - Backup job failure signal.
  - Node CPU/memory pressure and restart hot spots.

## Logs (Loki + Promtail)
- Loki deployed in single-binary mode for MVP speed and operational simplicity.
- Promtail runs as a DaemonSet and pushes Kubernetes logs to Loki with `cluster=freshcloud-mvp` label.
- Loki uses persistent storage on Longhorn (`50Gi`) to survive pod restarts.
- Grafana includes Loki as an additional data source for cross-navigation from metrics to logs.

## Alerting Strategy (Alertmanager)
- Trigger source: Prometheus rules (default kube-prometheus rules + FreshCloud high-signal rules).
- Routing model:
  - `critical`: page-on-call workflow (MVP integration target: webhook/PagerDuty/Opsgenie).
  - `warning`: ticket/Slack workflow for daylight-hours response.
- Grouping: by `alertname`, `namespace`, and severity to reduce notification noise.
- Repeat interval target: every 4h while unresolved.
- Operational policy: every firing alert must map to a runbook action and owner.

## High-Signal Alerts Implemented
The following five alerts are added in `/gitops/apps/observability/app-kube-prometheus-stack.yaml`:
1. `KubernetesAPIDown` (critical) — no reachable kube-apiserver target for 5m.
2. `KubernetesNodeNotReady` (critical) — node `Ready=true` condition is false for 10m.
3. `KubernetesNodeDiskPressure` (warning) — node reports disk pressure for 10m.
4. `CertificateExpirySoon` (warning) — cert-manager certificate expiry less than 7 days.
5. `BackupFailure` (critical) — backup/restore/snapshot related job failure in last hour.

## Suggested MVP SLOs
| Service Area | SLI | Target SLO | Error Budget (30d) |
|---|---|---|---|
| Kubernetes API | Successful API availability (`up` on apiserver targets) | 99.95% | 21m 36s |
| Node readiness | Nodes in `Ready=true` state | 99.9% per node | 43m 12s |
| Ingress/TLS | Valid cert before expiry and HTTPS success rate | 99.9% | 43m 12s |
| Logging pipeline | Log lines successfully ingested by Loki | 99.5% | 3h 36m |
| Backup reliability | Scheduled backup jobs finishing successfully | 99.0% | 7h 12m |

## Verification Procedure
1. Sync Argo CD apps:
   - `obs-kube-prometheus-stack`
   - `obs-loki`
   - `obs-promtail`
2. Validate runtime health:
   - `kubectl -n observability get pods`
   - `kubectl -n observability get pvc`
3. Validate alerts are loaded:
   - `kubectl -n observability get prometheusrules`
   - Open Prometheus rules UI and confirm `freshcloud.high-signal` group exists.
4. Validate Grafana visibility:
   - Open `FreshCloud Platform Overview` and check all panels return data.
   - Confirm default Kubernetes dashboards show node/pod state.
5. Validate logs:
   - Query Loki with `{namespace="kube-system"}` and `{namespace="observability"}` in Grafana Explore.

## Assumptions and To Verify (Leaseweb + Platform)
- [ ] Longhorn default storage class is available as `longhorn` in all environments.
- [ ] Alert delivery endpoint (PagerDuty/Opsgenie/webhook/SMTP) is available and managed via External Secrets.
- [ ] Retention (`15d` metrics, Loki volume `50Gi`) matches Leaseweb disk budget and IOPS profile.
- [ ] cert-manager is installed and exposes `certmanager_certificate_expiration_timestamp_seconds`.
- [ ] Backup jobs for Postgres/MinIO include naming pattern `backup|snapshot|wal|restore` (or alert rule regex must be adjusted).

## Day-1 and Day-2 Ops Notes
- Day-1: Review alerts and dashboard health daily; tune alert thresholds after first 2 weeks of production telemetry.
- Day-2: Run monthly alert-fire drills (synthetic API outage, cert-expiry simulation, and backup job failure simulation) and capture MTTD/MTTR.
