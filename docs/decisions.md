# FreshCloud Architecture Decisions (ADR)

## Work Item Contract
- Inputs: `docs/wbs.md` (`A-01`, `A-02`), `docs/architecture-mvp.md`, and MVP constraints from `AGENTS.md`.
- Outputs: ADR-style decisions for platform-critical choices that unblock infra, kubernetes, and gitops implementation.
- Acceptance Criteria: The six required decision areas (k8s distro, storage, ingress, GitOps, secrets, backups) are explicit, justified, and testable.
- How to Verify: Review each ADR for context, decision, consequences, owner, and objective verification checks.

## ADR Index
| ADR | Topic | Status | Date |
|---|---|---|---|
| ADR-001 | Kubernetes Distribution | Accepted | 2026-02-12 |
| ADR-002 | Storage Baseline | Accepted | 2026-02-12 |
| ADR-003 | Ingress and TLS | Accepted | 2026-02-12 |
| ADR-004 | GitOps Standard | Accepted | 2026-02-12 |
| ADR-005 | Secrets Management | Accepted | 2026-02-12 |
| ADR-006 | Backup and Restore Standard | Accepted | 2026-02-12 |

## ADR-001: Kubernetes Distribution = RKE2
- Status: Accepted
- Date: 2026-02-12
- Owner: Kubernetes Engineer
- Context: MVP requires a production-sensible Kubernetes baseline that can be bootstrapped fast on Leaseweb VMs and operated by a small team.
- Decision: Use RKE2 on 3 nodes (`cp+worker` on each node) with embedded etcd quorum.
- Alternatives Considered:
  - `kubeadm`: More manual lifecycle burden and more room for configuration drift.
  - `k3s`: Lightweight, but not preferred for this production-oriented baseline.
- Consequences:
  - Positive: Faster secure bootstrap and consistent defaults.
  - Tradeoff: Tooling and upgrade behavior align with RKE2 release cadence.
- Acceptance Criteria: `kubectl get nodes` shows 3 `Ready` nodes and control-plane health checks pass.
- How to Verify: Run `infra/ansible/playbooks/rke2-bootstrap.yml` and validate with `scripts/bootstrap/cluster-health.sh`.

## ADR-002: Storage Baseline = Longhorn
- Status: Accepted
- Date: 2026-02-12
- Owner: Kubernetes Engineer
- Context: MVP needs dynamic persistent volumes with HA behavior on VM-based nodes and built-in backup hooks.
- Decision: Use Longhorn as the default CSI storage layer, with two storage classes:
  - `longhorn-standard` (replica count 2) for general workloads.
  - `longhorn-critical` (replica count 3) for Postgres and MinIO.
- Alternatives Considered:
  - HostPath/local PV only: insufficient resilience.
  - Ceph/Rook: higher complexity than needed for MVP speed.
- Consequences:
  - Positive: Good resilience/complexity balance for MVP.
  - Tradeoff: Additional resource overhead on a 3-node cluster.
- Acceptance Criteria: PVC read/write survives single-node disruption for replicated volumes.
- How to Verify: Execute PVC smoke tests and node drain/failure test from `K-02` acceptance flow.

## ADR-003: Ingress and TLS = MetalLB + NGINX + cert-manager
- Status: Accepted
- Date: 2026-02-12
- Owner: Kubernetes Engineer
- Context: Leaseweb environment does not assume cloud-managed L4 load balancers; MVP still requires reliable public HTTPS ingress.
- Decision:
  - Use MetalLB to expose ingress service IP(s).
  - Use ingress-nginx as HTTP ingress controller.
  - Use cert-manager with Let's Encrypt for automated TLS issuance/renewal.
- Alternatives Considered:
  - Traefik as primary ingress: viable, but NGINX chosen for team familiarity and broad operational references.
  - Manual certificate management: rejected due to operational risk and toil.
- Consequences:
  - Positive: Automatable ingress/TLS baseline suitable for GitOps.
  - Tradeoff: Depends on Leaseweb network/IP behavior that must be verified.
- Acceptance Criteria: Public HTTPS endpoint is reachable with valid certificate chain.
- How to Verify: `curl https://<test-domain>` returns expected response and trusted cert in staging.

## ADR-004: GitOps Standard = Argo CD App-of-Apps
- Status: Accepted
- Date: 2026-02-12
- Owner: GitOps Engineer
- Context: MVP requires repeatable deployments across `dev/stage/prod` with clear auditability and minimal manual changes.
- Decision: Standardize on Argo CD using app-of-apps and Kustomize overlays for environment deltas.
- Alternatives Considered:
  - Flux: technically viable, but Argo CD chosen for current team workflow and visibility requirements.
  - Imperative `kubectl` deployment: rejected due to drift risk.
- Consequences:
  - Positive: Strong visibility and deterministic promotion path.
  - Tradeoff: Argo control-plane availability becomes operationally important.
- Acceptance Criteria: Root app syncs all platform components and unauthorized UI drift edits are blocked by process/RBAC.
- How to Verify: Validate Argo app health and run role-restricted access test for non-admin user.

## ADR-005: Secrets Management = SOPS + External Secrets
- Status: Accepted
- Date: 2026-02-12
- Owner: GitOps Engineer
- Context: Non-negotiable requirement is no plaintext secrets in Git, while still supporting namespace-level secret delivery.
- Decision:
  - Use SOPS (age) for encrypted secret manifests committed to Git.
  - Use External Secrets Operator (ESO) to distribute/refresh runtime Kubernetes secrets into target namespaces.
  - Keep decryption keys outside Git and rotate per security runbook.
- Alternatives Considered:
  - Plain Kubernetes Secrets in Git: rejected (security violation).
  - SOPS-only without ESO: acceptable for very small scope, but less ergonomic for cross-namespace secret distribution.
- Consequences:
  - Positive: Meets security baseline and GitOps workflow.
  - Tradeoff: Adds key management and ESO controller operations.
- Acceptance Criteria: Secret scans find no plaintext credentials in repo and workloads receive required secrets at runtime.
- How to Verify: Run secret scanning in CI and execute namespace secret sync test via ESO manifests.

## ADR-006: Backup and Restore Standard = Off-Cluster Backups + Mandatory Restore Drills
- Status: Accepted
- Date: 2026-02-12
- Owner: Data Services Engineer
- Context: MVP must prove recoverability, not just backup job success, for all critical stateful components.
- Decision:
  - Postgres (CloudNativePG): scheduled base backups + continuous WAL archiving to S3-compatible backup target.
  - MinIO: versioning/lifecycle policies plus scheduled backup/mirror to backup target.
  - Longhorn: recurring snapshot/backup jobs to S3-compatible target.
  - Restore drills (MinIO restore + Postgres PITR) are mandatory monthly; two consecutive passing drills required for MVP sign-off.
- Alternatives Considered:
  - In-cluster-only backups: rejected (insufficient disaster tolerance).
  - Backup-only compliance without restore tests: rejected (violates non-negotiable requirement).
- Consequences:
  - Positive: Objective recoverability evidence and reduced data-loss risk.
  - Tradeoff: Higher storage/egress cost and scheduled operational overhead.
- Acceptance Criteria: Restore drills meet published targets (`MinIO RTO <= 60m/RPO <= 24h`, `Postgres RTO <= 45m/RPO <= 15m`).
- How to Verify: Run timed restore tests from `docs/runbooks.md` and archive evidence in sprint exit artifacts.

## To Verify with Leaseweb (Decision Dependencies)
- [ ] Confirm S3-compatible endpoint capabilities needed for Longhorn/CNPG backup tooling.
- [ ] Confirm network/IP behavior needed by MetalLB to hold/advertise ingress VIPs.
- [ ] Confirm egress pricing impact for recurring backup and restore validation traffic.
- [ ] Confirm private network model supports current ingress and east-west assumptions.
- [ ] Confirm provider API coverage needed for full Terraform automation of edge/network primitives.
