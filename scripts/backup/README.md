# Backup Scripts Scaffold (Pi)

## Work Item Contract
- Inputs: Running MinIO/Postgres services and `scripts/backup/backup.env` with credentials/targets.
- Outputs: Timestamped backup artifacts and a basic artifact integrity smoke test.
- Acceptance Criteria: Backup scripts complete successfully and artifact validation passes.
- How to Verify: Run all scripts in sequence and confirm non-empty outputs in the backup directory.

## Files
- `backup.env.example`: variables template.
- `postgres-backup.sh`: creates a compressed Postgres backup using `pg_dump`.
- `minio-backup.sh`: mirrors selected MinIO buckets to local or remote target.
- `restore-smoke-test.sh`: validates backup artifacts are readable.

## Quick Start
```bash
cp scripts/backup/backup.env.example scripts/backup/backup.env
$EDITOR scripts/backup/backup.env
scripts/backup/postgres-backup.sh scripts/backup/backup.env
scripts/backup/minio-backup.sh scripts/backup/backup.env
scripts/backup/restore-smoke-test.sh scripts/backup/backup.env
```

## Notes
- This is a phase scaffold and not a full DR restore workflow.
- For full restore drills, combine with the `scripts/backup-test` suite.
