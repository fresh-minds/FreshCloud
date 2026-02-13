# GitOps Workflow (Argo CD)

## Work Item Contract
- Inputs: `AGENTS.md` non-negotiables, `docs/architecture-mvp.md` decisions (Argo CD, Kubernetes-first), and MVP requirement to bootstrap baseline services via GitOps.
- Outputs: Argo CD standard, repository layout (`clusters/`, `apps/`, `environments/`), promotion process (`dev`/`stage`/`prod`), and bootstrap runbook with verification commands.
- Acceptance Criteria: Fresh cluster reaches a running baseline (ingress, cert-manager, external-secrets) from Git state; no plaintext secrets in Git.
- How to Verify: Execute the commands in "Bootstrap Procedure" and "How to Verify"; confirm Argo Applications are `Synced/Healthy` and no plaintext `Secret` objects exist in tracked manifests.

## Chosen Tool
- Tool: **Argo CD** (standard for this repository).
- Why: app-of-apps bootstrap pattern, clear operational visibility, and straightforward promotion through Git pull requests.

## Repository Layout
```text
gitops/
├── bootstrap/
│   └── argocd/
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       ├── root-application-dev.yaml
│       ├── root-application-stage.yaml
│       └── root-application-prod.yaml
├── clusters/
│   ├── dev/kustomization.yaml
│   ├── stage/kustomization.yaml
│   └── prod/kustomization.yaml
├── environments/
│   ├── dev/
│   ├── stage/
│   └── prod/
└── apps/
    ├── ingress-nginx/base/
    ├── cert-manager/base/
    └── external-secrets/base/
```

- `apps/`: reusable baseline Argo `Application` manifests for shared platform components.
- `environments/`: environment overlays (version pins and labels via patches).
- `clusters/`: cluster entrypoints consumed by the Argo root application.

## App Delivery and Promotion Strategy
1. Merge platform/app change into `main` and update `gitops/environments/dev/patches/*.yaml` first.
2. Validate in `dev` (Argo health + smoke checks).
3. Promote by PR from `dev` version pins to `stage` patch files.
4. After `stage` validation, promote same version pins to `prod` via approved PR.

Promotion unit is the chart version in:
- `gitops/environments/dev/patches/*.yaml`
- `gitops/environments/stage/patches/*.yaml`
- `gitops/environments/prod/patches/*.yaml`

## Bootstrap Procedure
1. Set your Git repository URL in:
- `gitops/bootstrap/argocd/root-application-dev.yaml`
- `gitops/bootstrap/argocd/root-application-stage.yaml`
- `gitops/bootstrap/argocd/root-application-prod.yaml`

2. Install Argo CD on a fresh cluster:
```bash
kubectl apply -k gitops/bootstrap/argocd
kubectl -n argocd wait deploy/argocd-server --for=condition=Available --timeout=300s
```

3. Bootstrap one environment root app (example: dev):
```bash
kubectl apply -f gitops/bootstrap/argocd/root-application-dev.yaml
```

4. Argo CD reconciles baseline apps:
- ingress-nginx
- cert-manager
- external-secrets

## Secrets Approach
- This baseline installs **External Secrets Operator** (`gitops/apps/external-secrets/base/application.yaml`) and does not commit Kubernetes `Secret` manifests with plaintext values.
- For Git-stored secrets, use SOPS-encrypted files only (for example `*.enc.yaml`) and never plaintext `stringData` in tracked manifests.

## How to Verify
```bash
# Argo CD control plane is up
kubectl -n argocd get pods

# Root app and child apps exist
kubectl -n argocd get applications

# Baseline namespaces created by GitOps
kubectl get ns ingress-nginx cert-manager external-secrets

# Baseline workloads running
kubectl -n ingress-nginx get pods
kubectl -n cert-manager get pods
kubectl -n external-secrets get pods

# Guardrail: no plaintext Secret manifests in gitops/
rg -n "kind:\\s*Secret|stringData:" gitops
```

Expected result: platform applications are `Synced` and `Healthy`, baseline pods are `Running`, and the final `rg` command returns no matches.

## To Verify (Leaseweb Assumptions)
- [ ] Leaseweb network mode supports `LoadBalancer` service flow used by ingress (MetalLB/floating IP design).
- [ ] DNS automation path for ACME challenges is finalized (Leaseweb DNS API or external DNS provider).
- [ ] Preferred external secret backend for MVP is confirmed (Vault, cloud secret manager, or equivalent).
