#!/usr/bin/env bash
set -euo pipefail

expand_path() {
  local p="${1:-}"
  if [[ -z "${p}" ]]; then
    return 0
  fi
  if [[ "${p}" == ~* ]]; then
    printf '%s\n' "${p/#\~/${HOME}}"
  else
    printf '%s\n' "${p}"
  fi
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this script as root (use sudo)." >&2
    exit 1
  fi
}

load_env() {
  local env_file="${1:?env file is required}"
  if [[ ! -f "${env_file}" ]]; then
    echo "Environment file not found: ${env_file}" >&2
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "${env_file}"
  set +a
}

split_csv() {
  local value="${1:-}"
  local out_var="${2:?output variable name is required}"
  local clean
  clean="$(echo "${value}" | tr -d '[:space:]')"
  IFS=',' read -r -a values <<< "${clean}"
  eval "${out_var}=(\"\${values[@]}\")"
}

require_cmd() {
  local cmd="${1:?command is required}"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Required command not found: ${cmd}" >&2
    exit 1
  fi
}
