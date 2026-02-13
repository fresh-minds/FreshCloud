# AGENTS.md — FreshCloud on Leaseweb

You are working in the FreshCloud repository. This project sets up a Kubernetes-first “sovereign AI cloud” MVP on Leaseweb.

## Non-negotiables
- Prefer boring, production-sensible tech; ship an MVP fast.
- Everything repeatable must be automated (IaC + GitOps).
- Keep secrets out of Git. Use SOPS or External Secrets.
- Document assumptions about Leaseweb. Maintain a “To Verify” checklist.
- Every critical component needs backup + restore tests (not just backups).
- Write runbooks (day-0 provisioning, day-1 operations, day-2 upgrades/IR).

## Output rules
- For every work item: include **inputs**, **outputs**, **acceptance criteria**, and **how to verify**.
- Use markdown docs under `/docs`.
- Create scripts under `/scripts` and IaC under `/infra`.
- Prefer Argo CD or Flux for GitOps (choose one and standardize).

## MVP scope
- Leaseweb provisioning plan (manual steps documented + IaC where possible)
- Kubernetes cluster bootstrap (3 nodes minimum)
- Ingress + TLS
- Storage baseline
- Object storage (S3-compatible, e.g. MinIO) with backups
- Postgres with backups
- Observability stack (metrics + logs; traces optional)
- Security baseline (RBAC, network policies, secrets, audit approach)
- GitOps deployment pipeline + environments (dev/stage/prod minimal)

## Tone
Be decisive. If info is missing, state assumptions and proceed with a sensible default.