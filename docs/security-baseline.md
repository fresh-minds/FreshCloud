# FreshCloud Security Baseline (MVP)

## Work Item Contract
- Inputs: `docs/architecture-mvp.md`, `docs/wbs.md` (`S-01`, `S-02`, `S-03`), and FreshCloud non-negotiables from `AGENTS.md`.
- Outputs: Implementable baseline controls for RBAC, namespaces, secrets, network policy, container security, audit logging, and GDPR/BIO alignment.
- Acceptance Criteria: Controls are practical for the selected stack (RKE2, Argo CD, Kyverno, SOPS, External Secrets, Loki), and clearly split into `MVP now` and `later hardening`.
- How to Verify: Execute the verification checklist in each section; confirm control manifests can be deployed via GitOps and failing test cases are denied.

## Scope and Assumptions
- Scope: Single Leaseweb region, one RKE2 cluster, namespace-separated `dev`, `stage`, `prod` environments.
- GitOps: Argo CD is the only deployment path to cluster state.
- Policy engine: Kyverno is the default policy/admission tool for MVP.
- Secrets principle: plaintext secrets are never committed to Git.

## Security Principles
- Least privilege by default for people, service accounts, and network flows.
- Secure-by-default namespaces (`restricted` PSA where possible, default-deny network policies).
- Immutable, auditable change path (PR -> CI checks -> Argo CD sync).
- Backup and restore are mandatory controls for critical data services.

## Namespaces and RBAC Baseline

### Namespace Model
| Namespace | Purpose | Owner | Baseline PSA | Network Policy Posture |
|---|---|---|---|---|
| `argocd` | GitOps control plane | Platform | `baseline` | Ingress restricted to UI/API endpoints; egress only to Kubernetes API and Git endpoints |
| `ingress-nginx` | Ingress controller | Platform | `baseline` | Accept traffic from edge only; egress to app service CIDRs and DNS |
| `cert-manager` | Certificate automation | Platform | `baseline` | Egress only to ACME/DNS endpoints and Kubernetes API |
| `metallb-system` | L2/LB advertisement | Platform | `privileged` (documented exception) | Isolated; only required control-plane/node communications |
| `longhorn-system` | Storage system | Platform | `privileged` (documented exception) | Isolated; only storage replication/control traffic |
| `external-secrets` | Secret materialization controller | Security | `baseline` | Egress only to secret backend endpoints + Kubernetes API |
| `observability` | Prometheus/Grafana/Loki | SRE | `baseline` | Scrape/log access only to allowed namespaces and node exporters |
| `security` | Policy and security jobs | Security | `restricted` | No inbound from app namespaces; controlled egress |
| `dev` | Development workloads | App teams | `restricted` | Default deny; explicit allow from ingress and to env-local dependencies |
| `stage` | Pre-production workloads | App teams | `restricted` | Default deny; explicit allow from ingress and to env-local dependencies |
| `prod` | Production workloads | App teams | `restricted` | Default deny; strict egress allowlist and no cross-env access |

### RBAC Model (Least Privilege)
| Role Group | Scope | Allowed Actions | Explicit Denies / Guardrails |
|---|---|---|---|
| `platform-admins` | Cluster-wide | Manage platform namespaces, CRDs, node-level operations | No daily app changes in `prod`; break-glass use only with ticket + audit |
| `security-admins` | `security`, policy CRDs, audit configs | Manage Kyverno policies, security scans, audit pipelines | No direct writes to application deployments |
| `sre-observability` | `observability` + read cluster-wide | Manage monitoring/logging stack and alerts | No secrets read outside observability namespaces |
| `app-dev` | `dev` namespace | Deploy/update own workloads, view logs/events | No access to `stage`/`prod`, no RBAC modification rights |
| `app-stage` | `stage` namespace | Deploy/update stage workloads, run validation jobs | No access to `prod`, no cluster-scoped resources |
| `app-prod-ops` | `prod` namespace | Controlled rollout/restart/scale for prod workloads | No RBAC edits, no secret writes except via GitOps/ESO |
| `auditors` | Cluster-wide read-only | Read events, audit logs, RBAC objects, policy reports | No write actions |

### Service Account Rules
- Every workload uses a dedicated ServiceAccount.
- `automountServiceAccountToken: false` by default; opt-in only when API access is required.
- No wildcard `*` verbs/resources in Roles/ClusterRoles.
- ClusterRoleBindings are limited to platform/security controllers only.

## Secrets Management Approach (SOPS + External Secrets + Vault Path)

### MVP Now
- Authoring: secrets are created locally and encrypted with SOPS (`age` keys) before commit.
- Storage in Git: only encrypted `Secret` data or encrypted ExternalSecret bootstrap material is committed.
- Runtime delivery: External Secrets Operator (ESO) is deployed now; app manifests consume Kubernetes `Secret` objects created by ESO or SOPS-managed manifests.
- Secret classes:
  - Static low-rotation secrets: SOPS-encrypted manifests in GitOps repo.
  - Rotation-sensitive secrets (DB/app tokens): modeled as ExternalSecret resources so backend can be switched without app manifest changes.
- Key handling:
  - Age private key stored outside Git (operator workstation secret manager + CI secret store).
  - Key rotation every 90 days or on staff changes.

### Later Hardening
- Introduce HashiCorp Vault as primary secret backend for ESO (`ClusterSecretStore`) and migrate rotation-sensitive secrets first.
- Use dynamic secrets for Postgres roles and short TTL credentials where supported.
- Add auto-unseal and Vault HA with tested backup/restore runbook.

### Verification
- `rg -n "kind: Secret|stringData:" gitops/` shows no plaintext credentials.
- `sops -d <file>` works only with approved key material.
- `kubectl get externalsecret -A` shows `Ready=True` for expected secrets.
- Rotate one non-prod secret and verify app picks up updated value without manual patching.

## Network Policies Baseline

### MVP Now (Mandatory)
- Apply default deny ingress and egress in `dev`, `stage`, and `prod`.
- Allow DNS egress only to kube-dns/CoreDNS.
- Allow ingress to apps only from `ingress-nginx` namespace.
- Allow app egress only to:
  - env-local dependencies (for example service-to-service in same namespace),
  - shared platform endpoints explicitly required (for example metrics push, ESO webhook),
  - approved external endpoints via CIDR/FQDN policy where supported.
- Deny all cross-environment traffic (`dev` <-> `stage` <-> `prod`).

### Later Hardening
- Add egress gateway or CNI-level FQDN policy for strict outbound domain controls.
- Add anomaly detection on east-west traffic (for example Cilium Hubble/Falco network signals).

### Verification
- Deploy a test pod in `dev` attempting to call a `prod` service; connection must fail.
- Deploy a test pod with no policy exceptions; outbound internet access must fail.
- Verify ingress from `ingress-nginx` to app service succeeds.

## Container Security Baseline

### MVP Now
- Pod Security Admission labels:
  - `dev`, `stage`, `prod`: `enforce=restricted`, `audit=restricted`, `warn=restricted`.
  - Platform namespaces with system exceptions (`longhorn-system`, `metallb-system`, ingress controller): documented `baseline`/`privileged` exceptions with owner and reason.
- Kyverno baseline policies:
  - Block privileged containers, hostPath, hostNetwork, hostPID/IPC for app namespaces.
  - Require `runAsNonRoot`, `readOnlyRootFilesystem` where feasible, and dropped capabilities.
  - Block mutable image tags (`:latest`) in `stage`/`prod`.
- Image scanning hooks:
  - CI (GitHub Actions): Trivy image scan on build and PR.
  - Policy gate: fail pipeline on Critical CVEs in runtime OS/app packages.

### Later Hardening
- Enforce image signature verification (Cosign + Kyverno `verifyImages`) for `prod`.
- Add SBOM attestation checks and provenance verification (SLSA-oriented pipeline).
- Add runtime threat detection (Falco or equivalent).

### Verification
- Attempt to deploy a privileged pod in `dev`; admission must reject it.
- Attempt to deploy image tag `:latest` to `prod`; policy must reject it.
- CI security workflow blocks merge/deploy when Critical CVE threshold is exceeded.

## Audit Logging Approach

### MVP Now
- Enable Kubernetes API audit logging in RKE2 with an explicit audit policy file.
- Minimum captured events:
  - authn/authz decisions,
  - RBAC and policy object changes,
  - Secret create/update/delete metadata (no secret values),
  - workload deployment changes in `stage`/`prod`.
- Centralization pipeline:
  - API audit logs + Kubernetes events + Argo CD audit logs -> log shipper -> Loki.
- Retention:
  - Security/audit streams: minimum 180 days.
  - General platform logs: minimum 30 days.
- Access control:
  - Audit logs are read-only for `auditors`, mutable only by platform/security admins.

### Later Hardening
- Add immutable off-cluster archive (WORM-capable object storage) for security logs.
- Integrate SIEM correlation rules and alert triage playbooks.

### Verification
- Perform a controlled RBAC change; verify corresponding audit entries are queryable in Loki.
- Perform a denied API request with limited user; verify denial event is logged.
- Validate retention settings by checking Loki compactor/retention configuration and stored object age.

## GDPR/BIO-Aligned Checklist (High Level)

### MVP Now Checklist
| Control Theme | GDPR/BIO Intent | MVP Control |
|---|---|---|
| Data inventory and purpose limitation | GDPR Art. 5, BIO governance | Maintain data classification + processing register for all workloads before `prod` onboarding |
| Access control and least privilege | GDPR Art. 25/32, BIO IAM | Namespace RBAC model, MFA for Git/Leaseweb, break-glass process |
| Encryption and key management | GDPR Art. 32, BIO cryptography | TLS in transit, encrypted secrets with SOPS, key rotation runbook |
| Logging and accountability | GDPR Art. 5(2)/30, BIO logging | Central audit logging, immutable change history via GitOps |
| Backup and recoverability | GDPR availability/resilience, BIO continuity | Scheduled backups for MinIO/Postgres + monthly restore drills |
| Vulnerability management | GDPR security of processing, BIO ops security | Trivy scans in CI, policy-based deploy blocking for critical findings |
| Incident response and breach handling | GDPR Art. 33/34, BIO incident mgmt | Incident runbook with 72-hour breach notification decision path |
| Data retention and deletion | GDPR Art. 5(1)(e), BIO records | Define retention per dataset/log class and enforce deletion workflows |
| Vendor and residency controls | GDPR transfer rules, BIO supplier management | Leaseweb contract/DPA review, EU region pinning, subprocessors register |

### Later Hardening Checklist
- Formal DPIA workflow for high-risk processing.
- Periodic access recertification automation and SoD checks.
- Cryptographic key custody in HSM-backed KMS.
- External penetration testing and annual red-team exercise.
- SIEM/SOC integration with automated incident enrichment.

## Leaseweb Security To Verify
- [ ] Dedicated DPA terms, subprocessors list, and breach notification commitments.
- [ ] Region-level residency guarantees and cross-border transfer controls.
- [ ] Host-level audit/event feed availability for tenant workloads.
- [ ] Network DDoS protections and escalation path details.
- [ ] Object storage immutability (WORM/object-lock) support for audit evidence retention.
