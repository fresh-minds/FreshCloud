# Repository Scaffold Proposal

## Work Item Contract
- Inputs: Architecture decisions, WBS ownership model, MVP requirement for automation-first delivery.
- Outputs: A pragmatic monorepo structure for infrastructure, GitOps, scripts, and operations docs.
- Acceptance Criteria: Structure supports parallel work without merge chaos and enables environment promotion via GitOps.
- How to Verify: Teams can map every WBS deliverable path into this scaffold without ambiguity.

## Repo Tree (Proposed)
```text
FreshCloud/
├── docs/
│   ├── architecture-mvp.md
│   ├── wbs.md
│   ├── plan-sprints.md
│   ├── repo-scaffold.md
│   ├── runbooks.md
│   └── cost-rom.md
├── infra/
│   ├── terraform/
│   │   └── leaseweb/
│   │       ├── modules/
│   │       │   ├── network/
│   │       │   ├── compute/
│   │       │   └── security/
│   │       └── envs/
│   │           ├── mvp/
│   │           ├── stage/
│   │           └── prod/
│   └── ansible/
│       ├── inventories/
│       ├── playbooks/
│       └── roles/
├── gitops/
│   ├── bootstrap/
│   │   └── argocd/
│   ├── environments/
│   │   ├── dev/
│   │   ├── stage/
│   │   └── prod/
│   └── apps/
│       ├── platform/
│       ├── data/
│       ├── observability/
│       └── security/
├── scripts/
│   ├── bootstrap/
│   ├── ops/
│   ├── restore-tests/
│   └── finops/
├── .github/
│   └── workflows/
├── .sops.yaml
├── Makefile
└── README.md
```

## Tooling Standard
- IaC: Terraform for Leaseweb provisioning.
- Host/bootstrap automation: Ansible for RKE2 and base OS configuration.
- Kubernetes packaging: Helm charts wrapped by Kustomize overlays.
- GitOps: Argo CD app-of-apps (single standard).
- Secrets: SOPS (age) + External Secrets Operator.
- CI: GitHub Actions for `terraform validate`, manifest linting, policy checks, and secret scanning.
- Policy/Security: Kyverno or Gatekeeper (pick one in implementation, default Kyverno for speed).

## Environments and Promotion Strategy
- MVP default: single cluster, namespace-separated `dev`, `stage`, `prod` for fast delivery.
- Promotion model:
  1. Merge to `main` updates `dev` overlay automatically.
  2. Promotion to `stage` via PR (same manifests, overlay-only diffs).
  3. Promotion to `prod` via PR + required approvals + policy gate pass.
- Guardrails:
  - No direct edits in Argo CD UI.
  - All prod sync waves require approved pull request and green policy/security checks.
  - Secrets only via encrypted SOPS files or External Secrets references.

## Bootstrap Steps
1. Prepare workstation/tooling (`terraform`, `ansible`, `kubectl`, `helm`, `argocd`, `sops`, `age`).
2. Configure secrets and keys:
   - Generate/secure age keypair.
   - Configure CI secret for SOPS decryption.
3. Provision Leaseweb substrate:
   - `infra/terraform/leaseweb/envs/mvp` apply.
4. Bootstrap cluster:
   - Run Ansible playbooks in `infra/ansible/playbooks` for RKE2 install and baseline hardening.
5. Bootstrap GitOps:
   - Apply Argo CD bootstrap manifests from `gitops/bootstrap/argocd`.
6. Sync platform stack:
   - Deploy ingress/TLS, storage, security, observability, and data services via Argo root app.
7. Execute smoke + restore validation scripts:
   - `scripts/bootstrap/*` and `scripts/restore-tests/*`.
8. Record outputs:
   - Update `docs/runbooks.md` with environment-specific endpoints and operator commands.

## Assumptions
- Leaseweb API and networking capabilities are sufficient for Terraform-first provisioning.
- DNS control is available either via Leaseweb API or an external DNS provider.
- One-region deployment is acceptable for MVP; multi-region is post-MVP.
