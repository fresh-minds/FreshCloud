# FreshCloud

FreshCloud is an automation-first repository for building a Kubernetes-first "sovereign AI cloud" MVP on Leaseweb.

It combines:
- Infrastructure as Code for Leaseweb provisioning (`infra/terraform`)
- Host and cluster bootstrap automation (`infra/ansible`, `scripts/bootstrap`)
- GitOps deployment with Argo CD (`gitops/`)
- Data services and backup/restore validation (Postgres + MinIO)
- Observability baseline (Prometheus, Grafana, Loki, Promtail)
- Optional frontend platform dashboard (`frontend/`)

## What this repository currently delivers

- A documented Leaseweb target layout and provisioning checklist for a 3-node Kubernetes baseline plus edge and access nodes.
- RKE2 bootstrap automation with reproducible day-0 scripts.
- Baseline platform add-ons:
  - MetalLB
  - ingress-nginx
  - Longhorn
  - Argo CD
- GitOps scaffolding for environment overlays (`dev`, `stage`, `prod`) and platform apps (cert-manager, ingress-nginx, external-secrets, observability).
- Data service manifests and restore-test scripts for:
  - CloudNativePG (Postgres)
  - MinIO (S3-compatible object storage)
- Runbooks and decision docs for day-0/day-1/day-2 operations.

## Architecture defaults (MVP)

- Provider: Leaseweb (single region for MVP)
- Kubernetes: RKE2, 3-node control plane + worker topology
- GitOps: Argo CD (app-of-apps + Kustomize overlays)
- Ingress/TLS: ingress-nginx + cert-manager
- Storage: Longhorn
- Data: CloudNativePG + MinIO
- Observability: kube-prometheus-stack + Loki + Promtail
- Secrets: SOPS and/or External Secrets (no plaintext secrets in Git)

## Repository layout

```text
.
├── docs/                 # Architecture, runbooks, security, provisioning, ADRs
├── infra/                # Terraform (Leaseweb), Ansible, infra-level manifests
├── gitops/               # Argo CD bootstrap, apps, environments, clusters
├── scripts/              # Bootstrap, backup, restore tests, health checks
├── frontend/             # Optional React dashboard and K8s manifests
└── README.md
```

## Start here

1. Read project architecture and provisioning assumptions:
   - `docs/architecture-mvp.md`
   - `docs/leaseweb-provisioning.md`
   - `docs/gitops.md`
2. Review day-0/day-1/day-2 procedures:
   - `docs/runbooks.md`
3. Provision substrate (MVP env):
   - `infra/terraform/leaseweb/envs/mvp/README.md`
4. Bootstrap cluster and baseline add-ons:
   - `scripts/bootstrap/README.md`
5. Validate backup restore paths:
   - `docs/data-services.md`
   - `scripts/backup-test/run-all.sh`

## Quick commands

### Terraform plan (MVP)
```bash
cd infra/terraform/leaseweb/envs/mvp
cp terraform.tfvars.example terraform.tfvars
export LEASEWEB_TOKEN="<api-token>"
terraform init
terraform plan
```

### End-to-end cluster bootstrap
```bash
cp scripts/bootstrap/bootstrap.env.example scripts/bootstrap/bootstrap.env
cp scripts/bootstrap/ansible/inventory/hosts.ini.example scripts/bootstrap/ansible/inventory/hosts.ini
scripts/bootstrap/bootstrap-all.sh scripts/bootstrap/bootstrap.env scripts/bootstrap/ansible/inventory/hosts.ini
```

### Cluster health verification
```bash
scripts/bootstrap/cluster-health.sh
```

### Data restore validation
```bash
scripts/backup-test/run-all.sh
```

### Frontend (optional)
```bash
cd frontend
npm ci
npm run dev
```

## Important assumptions and gaps to verify

- Leaseweb API coverage for all network/firewall primitives is still partially provider-dependent.
- Floating/reserved IP behavior for ingress patterns must be validated for the target product tier.
- Backup object storage capabilities (encryption, retention/immutability, lifecycle policies) must be verified in the target account.

Track and close assumptions in:
- `docs/pi-to-verify.md`
- `docs/leaseweb-provisioning.md` (To Verify)
- `docs/architecture-mvp.md` (To Verify)

## Notes

- This repo contains some Raspberry Pi/K3s scaffolding from an earlier phase (`infra/k3s`, `scripts/pi-bootstrap`, Pi docs). The active MVP target is Leaseweb + RKE2.
- Keep secrets out of Git; use encrypted workflows (SOPS/External Secrets).
