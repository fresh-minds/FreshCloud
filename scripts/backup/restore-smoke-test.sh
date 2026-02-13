#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/backup.env}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file not found: ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

failures=0

latest_pg="$(ls -1t "${BACKUP_DIR%/}/postgres"/*.dump 2>/dev/null | head -n 1 || true)"
if [[ -z "${latest_pg}" ]]; then
  echo "[FAIL] No Postgres backup artifacts found."
  failures=$((failures + 1))
else
  if command -v pg_restore >/dev/null 2>&1 && pg_restore -l "${latest_pg}" >/dev/null 2>&1; then
    echo "[OK] Postgres backup is readable: ${latest_pg}"
  else
    echo "[FAIL] Postgres backup unreadable: ${latest_pg}"
    failures=$((failures + 1))
  fi
fi

latest_minio_dir="$(ls -1dt "${BACKUP_DIR%/}/minio"/* 2>/dev/null | head -n 1 || true)"
if [[ -z "${latest_minio_dir}" ]]; then
  echo "[FAIL] No MinIO backup artifacts found."
  failures=$((failures + 1))
else
  file_count="$(find "${latest_minio_dir}" -type f | wc -l | tr -d ' ')"
  if [[ "${file_count}" -gt 0 ]]; then
    echo "[OK] MinIO backup has files (${file_count}) in ${latest_minio_dir}"
  else
    echo "[FAIL] MinIO backup directory is empty: ${latest_minio_dir}"
    failures=$((failures + 1))
  fi
fi

if [[ "${failures}" -gt 0 ]]; then
  echo "Restore smoke test failed (${failures} checks)."
  exit 1
fi

echo "Restore smoke test passed."
