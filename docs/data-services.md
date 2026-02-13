# FreshCloud MVP Data Services (Postgres + S3 Object Storage)

## Work Item Contract
- Inputs: `AGENTS.md` MVP scope, `docs/architecture-mvp.md` platform choices, Argo CD GitOps standard, Leaseweb target environment.
- Outputs: Managed Postgres and MinIO manifests, automated backup jobs, and restore validation scripts with repeatable commands.
- Acceptance Criteria: Backups are scheduled automatically for Postgres and MinIO, and restore tests execute with deterministic PASS/FAIL outcomes.
- How to Verify: Apply data manifests through GitOps, run backup-test scripts in a cluster, and confirm PASS logs plus backup artifacts in object storage.

## GitOps Standard and Paths
- GitOps tool: Argo CD (single standard for this repo).
- Manifests root: `infra/gitops/apps/data`.
- Postgres manifests:
  - `infra/gitops/apps/data/postgres/cnpg-operator-application.yaml`
  - `infra/gitops/apps/data/postgres/cluster.yaml`
  - `infra/gitops/apps/data/postgres/scheduled-backup.yaml`
- MinIO manifests:
  - `infra/gitops/apps/data/minio/application.yaml`
  - `infra/gitops/apps/data/minio/backup-configmap.yaml`
  - `infra/gitops/apps/data/minio/backup-cronjob.yaml`
- Restore validation scripts:
  - `scripts/backup-test/postgres-restore-test.sh`
  - `scripts/backup-test/minio-restore-test.sh`
  - `scripts/backup-test/run-all.sh`

## Work Item D-01: Postgres Service
- Inputs: Kubernetes storage class (`longhorn`), S3-compatible backup endpoint, `pg-superuser`, `pg-app-user`, and `pg-backup-s3` secrets.
- Outputs: 3-instance CloudNativePG cluster with scheduled S3 backups and WAL archiving.
- Acceptance Criteria:
  - Cluster reports healthy primary + replicas.
  - Scheduled backup object exists and reaches `completed`.
  - Backup retention policy is set to 30 days.
- How to Verify:
  - `kubectl -n data-services get cluster.postgresql.cnpg.io freshcloud-pg`
  - `kubectl -n data-services get scheduledbackup.postgresql.cnpg.io freshcloud-pg-nightly`
  - `kubectl -n data-services get backup.postgresql.cnpg.io`

### Postgres Deployment Approach (Operator vs Helm Chart)
- Compared options:
  - Operator install + `Cluster` CRs (CloudNativePG-native lifecycle).
  - Single Helm chart for PostgreSQL pods.
- Decision: CloudNativePG operator.
- Why:
  - Native backup/recovery CRDs (`Backup`, `ScheduledBackup`, recovery bootstrap) reduce custom scripting.
  - Rolling updates, failover behavior, and day-2 operations are operator-managed.
  - Better HA and restore drill ergonomics for MVP than managing hand-rolled StatefulSet behavior.

### Postgres HA Posture
- Topology: `instances: 3` in one cluster (`freshcloud-pg`).
- Update strategy: `unsupervised` for automated primary switchover after replicas update.
- Storage: Longhorn-backed PVC (`100Gi`) for resilient node failure handling.
- Backup posture:
  - Continuous WAL archive + scheduled base backups to S3-compatible object storage.
  - 30-day retention policy at database backup layer.

## Work Item D-02: MinIO Service
- Inputs: `minio-root-credentials` secret, ingress DNS/TLS, Longhorn storage class, off-cluster S3 backup credentials (`minio-backup-s3`).
- Outputs: Distributed MinIO deployment (4 replicas) with scheduled backup sync job.
- Acceptance Criteria:
  - MinIO pods are healthy and S3 API responds.
  - `CronJob/minio-backup` runs on schedule and stores snapshot + latest backup paths.
  - Backup metadata file `last-successful-run.txt` is written in backup path.
- How to Verify:
  - `kubectl -n data-services get pods -l app.kubernetes.io/name=minio`
  - `kubectl -n data-services get cronjob minio-backup`
  - `kubectl -n data-services logs job/<manual-or-scheduled-backup-job>`

### MinIO Deployment Approach
- Decision: MinIO via Helm chart (Bitnami chart) managed by Argo CD `Application`.
- Why this for MVP:
  - Fast, repeatable deployment with explicit values in Git.
  - Distributed mode (`4` replicas) for erasure-coded availability.
  - Straightforward integration with ingress/TLS and namespace policies.

## Work Item D-03: Backup Strategy + Restore Validation
- Inputs: S3 backup endpoint (`backupEndpoint`), backup bucket (`backupBucket`), backup prefix (`backupPrefix`), Kubernetes access.
- Outputs: Automated backups and scripted restore tests with clear pass/fail outcomes.
- Acceptance Criteria:
  - Postgres backup and restore test passes.
  - MinIO backup and restore test passes.
  - Test evidence includes job names, marker IDs, and measured RTO output.
- How to Verify:
  - `scripts/backup-test/postgres-restore-test.sh`
  - `scripts/backup-test/minio-restore-test.sh`
  - `scripts/backup-test/run-all.sh`

## Backup Strategy

### Backup Destinations
- Primary destination for both services:
  - Endpoint: `https://s3.nl-ams-1.leaseweb.net`
  - Bucket: `freshcloud-backups`
- Prefix layout:
  - Postgres: `postgres/prod`
  - MinIO: `minio/prod/snapshots/<timestamp>` and `minio/prod/latest`

### Encryption
- In transit: TLS (`https`) for all S3 backup traffic.
- At rest:
  - Enforce server-side encryption (SSE-S3 or SSE-KMS) on backup bucket policy.
  - Keep application/database credentials in Kubernetes secrets sourced via External Secrets or SOPS-encrypted workflows.
- No plaintext credentials are committed to Git.

### Retention
- Postgres: `retentionPolicy: "30d"` in CloudNativePG cluster backup spec.
- MinIO: retention enforced by backup bucket lifecycle policy on `minio/prod/snapshots/*` (recommended 35 days minimum).

## Restore Test Procedure (Step-by-Step)

### Prerequisites
- Apply manifests via GitOps, then verify:
  - `kubectl -n data-services get cluster.postgresql.cnpg.io freshcloud-pg`
  - `kubectl -n data-services get cronjob minio-backup`
- Required secrets exist:
  - `pg-app-user` (`username`, `password`)
  - `pg-superuser`
  - `pg-backup-s3` (`ACCESS_KEY_ID`, `ACCESS_SECRET_ACCESS_KEY`)
  - `minio-root-credentials` (`root-user`, `root-password`)
  - `minio-backup-s3` (`ACCESS_KEY_ID`, `ACCESS_SECRET_ACCESS_KEY`)

### Postgres Restore Validation
1. Run:
   - `scripts/backup-test/postgres-restore-test.sh`
2. What the script does:
   - Inserts a unique restore marker row.
   - Creates an on-demand `Backup` CR.
   - Waits for backup phase `completed`.
   - Restores into a temporary `Cluster` from that backup.
   - Validates marker row exists in restored cluster.
3. Expected outcomes:
   - Logs include `PASS: Postgres restore validated successfully`.
   - Logs include `RTOSeconds=<value>`.
   - If marker lookup fails, script exits non-zero.

### MinIO Restore Validation
1. Run:
   - `scripts/backup-test/minio-restore-test.sh`
2. What the script does:
   - Writes a canary object to `restore-validation` bucket.
   - Triggers a manual job from `CronJob/minio-backup`.
   - Deletes the canary object in source bucket.
   - Restores canary object from `minio/prod/latest/...`.
   - Verifies restored content equals original marker value.
3. Expected outcomes:
   - Logs include `PASS: MinIO restore validated successfully`.
   - Backup and restore jobs complete with `succeeded=1`.
   - On mismatch or missing object, script exits non-zero.

### Combined Validation
1. Run:
   - `scripts/backup-test/run-all.sh`
2. Expected outcomes:
   - Both service tests pass in sequence.
   - Command exits `0`.

## Assumptions
- Argo CD is installed in namespace `argocd`.
- External secret plumbing exists for secret materialization (or equivalent SOPS flow).
- Storage class `longhorn` is available and default for stateful workloads.
- Leaseweb object storage endpoint and credentials support required S3 API operations (`PutObject`, `GetObject`, `ListBucket`).

## To Verify (Leaseweb + Environment-Specific)
- [ ] Confirm final Leaseweb object storage endpoint URL and region for production account.
- [ ] Confirm SSE enforcement mode available on backup bucket (SSE-S3/SSE-KMS).
- [ ] Confirm object lock/immutability availability for ransomware-resilient backups.
- [ ] Confirm bucket lifecycle policy can enforce `35d` snapshot retention for MinIO backup prefix.
- [ ] Confirm network egress policy allows data-services namespace to reach Leaseweb object storage endpoint.
- [ ] Confirm backup bucket quotas and egress costs meet MVP budget assumptions.
