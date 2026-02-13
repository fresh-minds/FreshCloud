#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

NAMESPACE="${NAMESPACE:-data-services}"
MINIO_SERVICE="${MINIO_SERVICE:-minio}"
SOURCE_BUCKET="${SOURCE_BUCKET:-restore-validation}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-1200}"
KEEP_ARTIFACTS="${KEEP_ARTIFACTS:-false}"
BACKUP_CONFIGMAP_NAME="${BACKUP_CONFIGMAP_NAME:-minio-backup-config}"
MINIO_SECRET_NAME="${MINIO_SECRET_NAME:-minio-root-credentials}"
MINIO_USER_SECRET_KEY="${MINIO_USER_SECRET_KEY:-root-user}"
MINIO_PASSWORD_SECRET_KEY="${MINIO_PASSWORD_SECRET_KEY:-root-password}"
BACKUP_SECRET_NAME="${BACKUP_SECRET_NAME:-minio-backup-s3}"
BACKUP_ACCESS_SECRET_KEY="${BACKUP_ACCESS_SECRET_KEY:-ACCESS_KEY_ID}"
BACKUP_SECRET_ACCESS_SECRET_KEY="${BACKUP_SECRET_ACCESS_SECRET_KEY:-ACCESS_SECRET_ACCESS_KEY}"
MC_IMAGE="${MC_IMAGE:-docker.io/bitnami/minio-client:2025.7.21-debian-12-r2}"

require_cmd kubectl date

timestamp="$(date -u +%Y%m%d%H%M%S)"
marker_value="minio-restore-marker-${timestamp}"
object_key="canary/${timestamp}.txt"
seed_job="minio-restore-seed-${timestamp}"
backup_job="minio-backup-manual-${timestamp}"
restore_job="minio-restore-verify-${timestamp}"

cleanup() {
  if [[ "${KEEP_ARTIFACTS}" == "true" ]]; then
    log "KEEP_ARTIFACTS=true, skipping cleanup"
    return
  fi

  log "Cleaning up temporary MinIO restore jobs"
  kubectl -n "${NAMESPACE}" delete job "${seed_job}" --ignore-not-found >/dev/null 2>&1 || true
  kubectl -n "${NAMESPACE}" delete job "${backup_job}" --ignore-not-found >/dev/null 2>&1 || true
  kubectl -n "${NAMESPACE}" delete job "${restore_job}" --ignore-not-found >/dev/null 2>&1 || true
}
trap cleanup EXIT

log "Creating canary object ${object_key} in bucket ${SOURCE_BUCKET}"
kubectl -n "${NAMESPACE}" delete job "${seed_job}" --ignore-not-found >/dev/null 2>&1 || true
cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: batch/v1
kind: Job
metadata:
  name: ${seed_job}
  namespace: ${NAMESPACE}
spec:
  backoffLimit: 1
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: mc
          image: ${MC_IMAGE}
          imagePullPolicy: IfNotPresent
          command:
            - /bin/bash
            - -ec
          args:
            - |
              set -euo pipefail
              mc alias set source "http://${MINIO_SERVICE}.${NAMESPACE}.svc.cluster.local:9000" "\${MINIO_ROOT_USER}" "\${MINIO_ROOT_PASSWORD}"
              mc mb --ignore-existing "source/${SOURCE_BUCKET}"
              printf "%s" "\${MARKER_VALUE}" | mc pipe "source/${SOURCE_BUCKET}/${object_key}"
          env:
            - name: MINIO_ROOT_USER
              valueFrom:
                secretKeyRef:
                  name: ${MINIO_SECRET_NAME}
                  key: ${MINIO_USER_SECRET_KEY}
            - name: MINIO_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${MINIO_SECRET_NAME}
                  key: ${MINIO_PASSWORD_SECRET_KEY}
            - name: MARKER_VALUE
              value: ${marker_value}
EOF
wait_for_job "${NAMESPACE}" "${seed_job}" "${TIMEOUT_SECONDS}"

log "Running manual MinIO backup job from CronJob/minio-backup"
kubectl -n "${NAMESPACE}" delete job "${backup_job}" --ignore-not-found >/dev/null 2>&1 || true
kubectl -n "${NAMESPACE}" create job --from=cronjob/minio-backup "${backup_job}" >/dev/null
wait_for_job "${NAMESPACE}" "${backup_job}" "${TIMEOUT_SECONDS}"

log "Simulating object loss and validating restore from backup target"
kubectl -n "${NAMESPACE}" delete job "${restore_job}" --ignore-not-found >/dev/null 2>&1 || true
cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: batch/v1
kind: Job
metadata:
  name: ${restore_job}
  namespace: ${NAMESPACE}
spec:
  backoffLimit: 1
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: mc
          image: ${MC_IMAGE}
          imagePullPolicy: IfNotPresent
          command:
            - /bin/bash
            - -ec
          args:
            - |
              set -euo pipefail
              source_object="${SOURCE_BUCKET}/${object_key}"
              backup_object="\${BACKUP_BUCKET}/\${BACKUP_PREFIX}/latest/\${source_object}"

              mc alias set source "http://${MINIO_SERVICE}.${NAMESPACE}.svc.cluster.local:9000" "\${MINIO_ROOT_USER}" "\${MINIO_ROOT_PASSWORD}"
              mc alias set backup "\${BACKUP_ENDPOINT}" "\${BACKUP_ACCESS_KEY_ID}" "\${BACKUP_SECRET_ACCESS_KEY}"

              mc rm --force "source/\${source_object}" || true
              mc cp "backup/\${backup_object}" "source/\${source_object}"

              restored_value="$(mc cat "source/\${source_object}")"
              if [[ "\${restored_value}" != "\${MARKER_VALUE}" ]]; then
                echo "Expected '\${MARKER_VALUE}', got '\${restored_value}'"
                exit 1
              fi
          env:
            - name: MINIO_ROOT_USER
              valueFrom:
                secretKeyRef:
                  name: ${MINIO_SECRET_NAME}
                  key: ${MINIO_USER_SECRET_KEY}
            - name: MINIO_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${MINIO_SECRET_NAME}
                  key: ${MINIO_PASSWORD_SECRET_KEY}
            - name: BACKUP_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: ${BACKUP_SECRET_NAME}
                  key: ${BACKUP_ACCESS_SECRET_KEY}
            - name: BACKUP_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: ${BACKUP_SECRET_NAME}
                  key: ${BACKUP_SECRET_ACCESS_SECRET_KEY}
            - name: BACKUP_ENDPOINT
              valueFrom:
                configMapKeyRef:
                  name: ${BACKUP_CONFIGMAP_NAME}
                  key: backupEndpoint
            - name: BACKUP_BUCKET
              valueFrom:
                configMapKeyRef:
                  name: ${BACKUP_CONFIGMAP_NAME}
                  key: backupBucket
            - name: BACKUP_PREFIX
              valueFrom:
                configMapKeyRef:
                  name: ${BACKUP_CONFIGMAP_NAME}
                  key: backupPrefix
            - name: MARKER_VALUE
              value: ${marker_value}
EOF
wait_for_job "${NAMESPACE}" "${restore_job}" "${TIMEOUT_SECONDS}"

log "PASS: MinIO restore validated successfully"
log "PASS: Object=${object_key} Marker=${marker_value} BackupJob=${backup_job}"
