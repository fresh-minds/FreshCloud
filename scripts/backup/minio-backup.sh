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

if ! command -v mc >/dev/null 2>&1; then
  echo "Required command not found: mc (MinIO client)." >&2
  exit 1
fi

if [[ -z "${MINIO_SOURCE_ENDPOINT:-}" || -z "${MINIO_SOURCE_ACCESS_KEY:-}" || -z "${MINIO_SOURCE_SECRET_KEY:-}" ]]; then
  echo "MINIO source configuration is incomplete." >&2
  exit 1
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
out_dir="${BACKUP_DIR%/}/minio/${timestamp}"
mkdir -p "${out_dir}"

mc alias set src "${MINIO_SOURCE_ENDPOINT}" "${MINIO_SOURCE_ACCESS_KEY}" "${MINIO_SOURCE_SECRET_KEY}" >/dev/null

IFS=',' read -r -a buckets <<< "$(echo "${MINIO_BUCKETS:-}" | tr -d '[:space:]')"
if [[ "${#buckets[@]}" -eq 0 || -z "${buckets[0]}" ]]; then
  echo "MINIO_BUCKETS must contain at least one bucket." >&2
  exit 1
fi

if [[ -n "${MINIO_TARGET_ENDPOINT:-}" && -n "${MINIO_TARGET_ACCESS_KEY:-}" && -n "${MINIO_TARGET_SECRET_KEY:-}" ]]; then
  mc alias set dst "${MINIO_TARGET_ENDPOINT}" "${MINIO_TARGET_ACCESS_KEY}" "${MINIO_TARGET_SECRET_KEY}" >/dev/null
  for bucket in "${buckets[@]}"; do
    dest="dst/${MINIO_TARGET_PREFIX%/}/${timestamp}/${bucket}"
    mc mirror --overwrite "src/${bucket}" "${dest}"
    echo "Mirrored src/${bucket} -> ${dest}"
  done
else
  for bucket in "${buckets[@]}"; do
    dest="${out_dir}/${bucket}"
    mc mirror --overwrite "src/${bucket}" "${dest}"
    echo "Mirrored src/${bucket} -> ${dest}"
  done
fi

echo "MinIO backup completed."
