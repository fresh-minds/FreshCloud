#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/bootstrap.env}"
INVENTORY_FILE="${2:-${SCRIPT_DIR}/ansible/inventory/hosts.ini}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file not found: ${ENV_FILE}" >&2
  echo "Copy ${SCRIPT_DIR}/bootstrap.env.example to ${SCRIPT_DIR}/bootstrap.env and edit values." >&2
  exit 1
fi

if [[ ! -f "${INVENTORY_FILE}" ]]; then
  echo "Inventory file not found: ${INVENTORY_FILE}" >&2
  echo "Copy ${SCRIPT_DIR}/ansible/inventory/hosts.ini.example and set host/IP values." >&2
  exit 1
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ansible-playbook is required on the operator workstation." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${RKE2_TOKEN:?RKE2_TOKEN must be defined in ${ENV_FILE}}"

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
  -i "${INVENTORY_FILE}" \
  "${SCRIPT_DIR}/ansible/rke2-bootstrap.yml"

echo "RKE2 bootstrap playbook completed."
