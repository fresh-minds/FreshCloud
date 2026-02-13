#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

NAMESPACE="${NAMESPACE:-data-services}"
PG_CLUSTER="${PG_CLUSTER:-freshcloud-pg}"
APP_DATABASE="${APP_DATABASE:-app}"
APP_SECRET_NAME="${APP_SECRET_NAME:-pg-app-user}"
RESTORE_STORAGE_CLASS="${RESTORE_STORAGE_CLASS:-longhorn}"
RESTORE_STORAGE_SIZE="${RESTORE_STORAGE_SIZE:-20Gi}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-1800}"
KEEP_ARTIFACTS="${KEEP_ARTIFACTS:-false}"

require_cmd kubectl base64 tr date

timestamp="$(date -u +%Y%m%d%H%M%S)"
marker="pg-restore-marker-${timestamp}"
backup_name="${PG_CLUSTER}-manual-${timestamp}"
restore_cluster="${PG_CLUSTER}-restore-${timestamp}"

cleanup() {
  if [[ "${KEEP_ARTIFACTS}" == "true" ]]; then
    log "KEEP_ARTIFACTS=true, skipping cleanup"
    return
  fi

  log "Cleaning up restore resources"
  kubectl -n "${NAMESPACE}" delete cluster.postgresql.cnpg.io "${restore_cluster}" --ignore-not-found >/dev/null 2>&1 || true
  kubectl -n "${NAMESPACE}" delete backup.postgresql.cnpg.io "${backup_name}" --ignore-not-found >/dev/null 2>&1 || true
}
trap cleanup EXIT

log "Checking source Postgres cluster ${PG_CLUSTER}"
kubectl -n "${NAMESPACE}" get cluster.postgresql.cnpg.io "${PG_CLUSTER}" >/dev/null

source_pod="$(kubectl -n "${NAMESPACE}" get pods -l "cnpg.io/cluster=${PG_CLUSTER}" -o jsonpath='{.items[0].metadata.name}')"
if [[ -z "${source_pod}" ]]; then
  fail "No CNPG pods found for cluster ${PG_CLUSTER} in namespace ${NAMESPACE}"
fi

pg_user_b64="$(kubectl -n "${NAMESPACE}" get secret "${APP_SECRET_NAME}" -o jsonpath='{.data.username}')"
pg_password_b64="$(kubectl -n "${NAMESPACE}" get secret "${APP_SECRET_NAME}" -o jsonpath='{.data.password}')"
pg_user="$(decode_base64 "${pg_user_b64}")"
pg_password="$(decode_base64 "${pg_password_b64}")"
if [[ -z "${pg_user}" || -z "${pg_password}" ]]; then
  fail "Could not decode username/password from secret ${APP_SECRET_NAME}"
fi

log "Writing restore marker '${marker}' to source cluster"
kubectl -n "${NAMESPACE}" exec "${source_pod}" -- \
  env "PGPASSWORD=${pg_password}" \
  psql "host=${PG_CLUSTER}-rw user=${pg_user} dbname=${APP_DATABASE} sslmode=disable" \
  -v ON_ERROR_STOP=1 \
  -c "CREATE TABLE IF NOT EXISTS restore_validation (marker text PRIMARY KEY, inserted_at timestamptz NOT NULL DEFAULT now());" >/dev/null

kubectl -n "${NAMESPACE}" exec "${source_pod}" -- \
  env "PGPASSWORD=${pg_password}" \
  psql "host=${PG_CLUSTER}-rw user=${pg_user} dbname=${APP_DATABASE} sslmode=disable" \
  -v ON_ERROR_STOP=1 \
  -c "INSERT INTO restore_validation(marker) VALUES ('${marker}');" >/dev/null

log "Creating on-demand backup ${backup_name}"
cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: ${backup_name}
  namespace: ${NAMESPACE}
spec:
  cluster:
    name: ${PG_CLUSTER}
EOF

wait_for_cnpg_backup "${NAMESPACE}" "${backup_name}" "${TIMEOUT_SECONDS}"

log "Restoring backup ${backup_name} into cluster ${restore_cluster}"
restore_started_epoch="$(date +%s)"
cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: ${restore_cluster}
  namespace: ${NAMESPACE}
spec:
  instances: 1
  storage:
    storageClass: ${RESTORE_STORAGE_CLASS}
    size: ${RESTORE_STORAGE_SIZE}
  bootstrap:
    recovery:
      backup:
        name: ${backup_name}
EOF

kubectl -n "${NAMESPACE}" wait --for=condition=Ready pod -l "cnpg.io/cluster=${restore_cluster}" --timeout="${TIMEOUT_SECONDS}s" >/dev/null
restore_finished_epoch="$(date +%s)"
rto_seconds=$((restore_finished_epoch - restore_started_epoch))

restored_count="$(
  kubectl -n "${NAMESPACE}" exec "${source_pod}" -- \
    env "PGPASSWORD=${pg_password}" \
    psql "host=${restore_cluster}-rw user=${pg_user} dbname=${APP_DATABASE} sslmode=disable" \
    -v ON_ERROR_STOP=1 \
    -tAc "SELECT count(*) FROM restore_validation WHERE marker = '${marker}';" \
  | tr -d '[:space:]'
)"

if [[ "${restored_count}" != "1" ]]; then
  fail "Restore validation failed: marker '${marker}' not found (count=${restored_count:-0})"
fi

log "PASS: Postgres restore validated successfully"
log "PASS: Backup=${backup_name} RestoreCluster=${restore_cluster} Marker=${marker} RTOSeconds=${rto_seconds}"
