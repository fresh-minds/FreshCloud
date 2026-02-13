#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

fail() {
  log "ERROR: $*"
  exit 1
}

require_cmd() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      fail "Required command not found: ${cmd}"
    fi
  done
}

decode_base64() {
  local value="$1"
  if base64 --decode >/dev/null 2>&1 <<<""; then
    printf '%s' "${value}" | base64 --decode
    return 0
  fi
  if base64 -d >/dev/null 2>&1 <<<""; then
    printf '%s' "${value}" | base64 -d
    return 0
  fi
  if base64 -D >/dev/null 2>&1 <<<""; then
    printf '%s' "${value}" | base64 -D
    return 0
  fi
  fail "No supported base64 decode flag found (--decode, -d, -D)"
}

wait_for_cnpg_backup() {
  local namespace="$1"
  local backup_name="$2"
  local timeout_seconds="$3"
  local end_at=$((SECONDS + timeout_seconds))

  while (( SECONDS < end_at )); do
    local phase
    phase="$(kubectl -n "${namespace}" get backup.postgresql.cnpg.io "${backup_name}" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    case "${phase}" in
      completed)
        log "Backup ${backup_name} reached phase=completed"
        return 0
        ;;
      failed|walArchivingFailing)
        kubectl -n "${namespace}" describe backup.postgresql.cnpg.io "${backup_name}" || true
        fail "Backup ${backup_name} reached failure phase=${phase}"
        ;;
      *)
        log "Waiting for backup ${backup_name} (phase=${phase:-pending})"
        sleep 10
        ;;
    esac
  done

  kubectl -n "${namespace}" describe backup.postgresql.cnpg.io "${backup_name}" || true
  fail "Timed out waiting for backup ${backup_name} after ${timeout_seconds}s"
}

wait_for_job() {
  local namespace="$1"
  local job_name="$2"
  local timeout_seconds="$3"
  local end_at=$((SECONDS + timeout_seconds))

  while (( SECONDS < end_at )); do
    local succeeded failed
    succeeded="$(kubectl -n "${namespace}" get job "${job_name}" -o jsonpath='{.status.succeeded}' 2>/dev/null || true)"
    failed="$(kubectl -n "${namespace}" get job "${job_name}" -o jsonpath='{.status.failed}' 2>/dev/null || true)"

    if [[ "${succeeded}" == "1" ]]; then
      log "Job ${job_name} completed successfully"
      return 0
    fi

    if [[ -n "${failed}" && "${failed}" != "0" ]]; then
      kubectl -n "${namespace}" logs "job/${job_name}" --all-containers=true || true
      fail "Job ${job_name} failed"
    fi

    log "Waiting for job ${job_name} to complete"
    sleep 5
  done

  kubectl -n "${namespace}" describe job "${job_name}" || true
  kubectl -n "${namespace}" logs "job/${job_name}" --all-containers=true || true
  fail "Timed out waiting for job ${job_name} after ${timeout_seconds}s"
}
