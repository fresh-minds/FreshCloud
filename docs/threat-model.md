# FreshCloud Threat Model (Lightweight)

## Work Item Contract
- Inputs: `docs/architecture-mvp.md`, `docs/security-baseline.md`, and WBS security tasks (`S-01` to `S-03`).
- Outputs: A concise threat model with key threats, likely attack paths, practical mitigations, and verification checks.
- Acceptance Criteria: Threats are relevant to FreshCloud MVP architecture and each threat has implementable `MVP now` mitigations plus `later hardening` options.
- How to Verify: Run the validation tests listed per threat and confirm preventive/detective controls produce expected evidence.

## Scope
- In scope: Kubernetes control plane, GitOps pipeline, workload namespaces (`dev`, `stage`, `prod`), Postgres, MinIO, backup flows, and operator access.
- Out of scope (MVP): multi-region failover, full SOC automation, and advanced runtime behavioral analytics.

## Critical Assets
- Customer and platform data in Postgres and MinIO.
- Credentials (Leaseweb, Git, Kubernetes, CI tokens, app secrets).
- GitOps source of truth and deployment pipeline.
- Backups and restore artifacts.
- Audit evidence and incident timelines.

## Trust Boundaries
- Internet to ingress boundary (`MetalLB` + `ingress-nginx`).
- Human/admin boundary (IdP users -> Kubernetes/Git/Leaseweb access).
- CI/CD boundary (GitHub Actions -> container registry -> Argo CD).
- Cluster internal boundary (namespace-to-namespace traffic).
- Data boundary (workloads -> Postgres/MinIO/backups).

## Key Threats and Mitigations
| ID | Threat | Likely Attack Path | Impact | MVP Now Mitigations | Later Hardening |
|---|---|---|---|---|---|
| T1 | Admin identity compromise | Phished or leaked credentials for Git, Leaseweb, or Kubernetes | Full platform takeover | SSO + MFA, least-privilege RBAC, break-glass account controls, audit logging for privileged actions | JIT access, hardware-backed phishing-resistant MFA, automated access recertification |
| T2 | Secret leakage | Plaintext secret in Git/CI logs or over-broad secret read permissions | Unauthorized data/system access | SOPS encryption, ESO abstraction, restricted secret RBAC, secret scanning in CI | Vault-backed dynamic secrets, automatic secret rotation, workload identity federation |
| T3 | Supply-chain compromise | Malicious/vulnerable container image or Helm chart | Remote code execution, data exfiltration | Pin image digests, Trivy CI scan with fail gates, block `:latest`, approved registries only | Signature verification (Cosign), SBOM/provenance enforcement, admission attestations |
| T4 | Namespace lateral movement | Compromised pod pivots to other namespaces/services | Cross-env compromise | Default-deny ingress/egress, no cross-env network policy exceptions, namespace-scoped service accounts | Service mesh mTLS + identity-based policy, east-west anomaly detection |
| T5 | Public exposure misconfiguration | Service/Ingress or LB config accidentally exposes internal apps/data | Data breach and service abuse | GitOps-only changes, ingress allowlist patterns, policy checks for LoadBalancer/NodePort usage, periodic external exposure review | Continuous attack-surface scanning and auto-remediation |
| T6 | Data loss or ransomware behavior | Destructive delete/encrypt actions in DB/object storage | Service outage and permanent data loss | Scheduled backups, off-cluster backup copy, monthly restore drill with RTO/RPO checks | Immutable backups (WORM), cross-region backup replication |
| T7 | Audit trail tampering or gaps | Logging disabled, insufficient retention, or unauthorized log edits | Forensics failure and compliance breach | RKE2 API audit logs enabled, centralized logs in Loki, role-based read-only auditor access, retention policy checks | Immutable audit archive, SIEM correlation and integrity verification |
| T8 | Container escape/host compromise | Privileged pod, kernel exploit, hostPath abuse | Cluster-wide compromise | PSA restricted for app namespaces, Kyverno policy blocks privileged patterns, node patch cadence and minimal host access | Runtime detection (Falco), hardened node OS profiles, eBPF threat detection |

## MVP Now Validation Plan
| Threat IDs | Validation Test | Expected Evidence |
|---|---|---|
| `T1`, `T7` | Run a controlled RBAC privilege change and denied API action | Audit records in Loki with actor, verb, resource, timestamp |
| `T2` | Repo and CI secret scan on pull request | Build fails on detected plaintext secret pattern |
| `T3` | Push image with known Critical CVE to non-prod pipeline | CI gate fails and deployment is blocked |
| `T4` | Attempt `dev` pod to connect to `prod` service | Connection denied by NetworkPolicy |
| `T5` | Attempt to create unauthorized `Service type=LoadBalancer` in app namespace | Admission/policy rejection event logged |
| `T6` | Monthly restore drill for Postgres PITR and MinIO object set | Measured RTO/RPO report and successful data integrity checks |
| `T8` | Attempt to deploy privileged pod in `dev` | Admission rejection with policy reason |

## Residual Risks (Accepted for MVP)
- Single-region deployment means regional outage risk is not eliminated.
- Full immutable log archive and SIEM correlation are deferred.
- Vault-backed dynamic secrets are deferred; some static secrets remain SOPS-managed.

## Review Cadence
- Re-run this threat model at each sprint boundary and before production go-live.
- Mandatory update triggers:
  - new internet-facing component,
  - new data category (especially personal/sensitive data),
  - change in secret backend or identity provider,
  - major Kubernetes or ingress architecture change.
