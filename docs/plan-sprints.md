# Parallel Execution Plan and Sprint Breakdown

## Work Item Contract
- Inputs: `docs/architecture-mvp.md` and `docs/wbs.md` task graph.
- Outputs: A parallelized execution plan with clear critical path and sprint exit gates.
- Acceptance Criteria: Plan allows immediate multi-agent start, preserves dependency order, and defines objective sprint completion tests.
- How to Verify: Trace each sprint task back to WBS IDs and confirm no critical dependency is scheduled after its dependent.

## Parallel Execution: What Starts Immediately
These tasks can start in parallel on day 1:
- Platform Architect: `A-01`, `A-02`
- Leaseweb Infra Engineer: `L-01`
- Kubernetes Engineer: prepare playbook scaffolding for `K-01` (blocked only on `L-02` inventory)
- GitOps Engineer: repo scaffolding for `G-02` and Argo bootstrap manifests for `G-01`
- Security & Compliance: baseline policy manifests draft for `S-01`
- Observability SRE: dashboards/alerts draft for `O-01`
- Data Services Engineer: manifests draft for `D-01` and `D-02`
- FinOps: `F-01`

## Critical Path
Primary go-live critical path:
1. `L-01` -> `L-02` -> `L-03`
2. `K-01` -> `K-03` -> `G-01`
3. `G-02` -> `G-03`
4. `K-02` -> `D-02` -> `D-03`
5. `O-01` -> `O-02` -> `O-03`
6. `A-03` readiness gate sign-off

Critical path notes:
- `D-03` (restore drills) and `O-03` (SLO visibility) are mandatory before MVP sign-off.
- If Leaseweb edge assumptions fail (`L-03`), fallback is manual edge provisioning with the same acceptance tests.

## Sprint 0 (Foundation)
- Duration: 2 weeks
- Goal: Provision substrate and establish repeatable cluster bootstrap + GitOps control plane.
- WBS scope: `A-01`, `A-02`, `L-01`, `L-02`, `L-03`, `K-01`, `G-01`, `F-01`
- Inputs: Leaseweb account access, domain ownership, repository access, architecture assumptions.
- Outputs: Running 3-node RKE2 cluster with Argo CD bootstrap and codified infra modules.
- Acceptance Criteria:
  - Terraform modules and environment plans validated.
  - 3-node cluster healthy (`Ready`) with hardened access.
  - Argo CD root app syncs successfully.
  - Initial cost baseline published.
- How to Verify:
  - `terraform validate` + plan output for MVP env.
  - `kubectl get nodes` and control-plane health checks.
  - Argo CD app health status = Healthy/Synced.
  - `docs/cost-rom.md` reviewed and approved.

## Sprint 1 (Platform Services)
- Duration: 2 weeks
- Goal: Deliver ingress, storage, security baseline, data services, and core observability.
- WBS scope: `K-02`, `K-03`, `G-02`, `G-03`, `S-01`, `S-02`, `O-01`, `O-02`, `D-01`, `D-02`
- Inputs: Sprint 0 cluster + GitOps baseline, edge prerequisites.
- Outputs: Production-sensible platform stack running via GitOps in `dev/stage/prod` namespaces.
- Acceptance Criteria:
  - HTTPS ingress works with automated cert issuance.
  - Longhorn-backed PVCs stable across node disruption.
  - MinIO and Postgres deployed with successful scheduled backups.
  - Metrics and logs centralized in Grafana.
  - Baseline policy controls actively enforce security constraints.
- How to Verify:
  - Public HTTPS smoke test and cert chain validation.
  - Storage failover/PVC continuity test.
  - Backup job success plus restore catalog visibility.
  - Synthetic metrics/log checks.
  - Security policy violation tests produce expected denials.

## Sprint 2 (Readiness, Resilience, and Operations)
- Duration: 2 weeks
- Goal: Prove recoverability, finalize operations model, and set scale/cost controls.
- WBS scope: `D-03`, `O-03`, `S-03`, `A-03`, `F-02`, `F-03`
- Inputs: Stable platform services, backup artifacts, observability data.
- Outputs: Restore-tested MVP with runbooks, SLOs, incident controls, and scale triggers.
- Acceptance Criteria:
  - Restore drills pass twice consecutively (MinIO + Postgres PITR).
  - SLO dashboards and paging rules validated.
  - Audit logs centralized with retention controls.
  - Budget alerts and scale triggers documented and testable.
- How to Verify:
  - Timed restore drill evidence recorded.
  - Alert fire-and-recover exercises completed.
  - Audit event retrieval from centralized logs.
  - Simulated budget breach triggers notification path.

## Exit Criteria by Sprint
- Sprint 0 exit: infrastructure and control plane repeatable from clean environment.
- Sprint 1 exit: all core platform/data services available through GitOps with baseline security and observability.
- Sprint 2 exit: recoverability and operations proven; go-live checklist signed by all owner agents.
