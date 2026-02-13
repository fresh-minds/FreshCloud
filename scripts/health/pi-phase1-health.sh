#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PI_SCRIPT_DIR="${ROOT_DIR}/pi-bootstrap"
ENV_FILE="${1:-${PI_SCRIPT_DIR}/pi.env}"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

failures=0

check_cmd() {
  local name="${1:?name is required}"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "[OK] ${name}"
  else
    echo "[FAIL] ${name}"
    failures=$((failures + 1))
  fi
}

check_service_active() {
  local service="${1:?service is required}"
  local name="${2:?name is required}"
  if systemctl is-active --quiet "${service}"; then
    echo "[OK] ${name}"
  else
    echo "[FAIL] ${name}"
    failures=$((failures + 1))
  fi
}

check_service_active "ssh" "SSH service active"

if [[ "${ENABLE_UFW:-true}" == "true" ]]; then
  if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "^Status: active"; then
      echo "[OK] UFW enabled"
    else
      echo "[FAIL] UFW enabled"
      failures=$((failures + 1))
    fi
  else
    echo "[FAIL] ufw command not installed"
    failures=$((failures + 1))
  fi
else
  echo "[SKIP] UFW check disabled by ENABLE_UFW=false"
fi

if [[ "${ENABLE_FAIL2BAN:-true}" == "true" ]]; then
  check_service_active "fail2ban" "Fail2ban active"
else
  echo "[SKIP] Fail2ban check disabled by ENABLE_FAIL2BAN=false"
fi

if [[ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null || true)" == "yes" ]]; then
  echo "[OK] NTP enabled"
else
  echo "[FAIL] NTP enabled"
  failures=$((failures + 1))
fi

if command -v tailscale >/dev/null 2>&1; then
  check_service_active "tailscaled" "Tailscale daemon active"
  check_cmd "Tailscale has IPv4" tailscale ip -4
else
  echo "[WARN] tailscale command not installed"
fi

if [[ -n "${PI_HOSTNAME:-}" ]]; then
  if [[ "$(hostname)" == "${PI_HOSTNAME}" ]]; then
    echo "[OK] Hostname matches ${PI_HOSTNAME}"
  else
    echo "[FAIL] Hostname mismatch: expected ${PI_HOSTNAME}, got $(hostname)"
    failures=$((failures + 1))
  fi
fi

if [[ "${failures}" -gt 0 ]]; then
  echo "Health check failed (${failures} checks)."
  exit 1
fi

echo "Health check passed."
