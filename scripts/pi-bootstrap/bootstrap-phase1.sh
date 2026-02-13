#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/pi.env}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root (use sudo)." >&2
  exit 1
fi

"${SCRIPT_DIR}/prepare-host.sh" "${ENV_FILE}"
"${SCRIPT_DIR}/harden-host.sh" "${ENV_FILE}"
"${SCRIPT_DIR}/install-tailscale.sh" "${ENV_FILE}"

echo "Phase 1 bootstrap completed."
echo "Run: scripts/health/pi-phase1-health.sh ${ENV_FILE}"
