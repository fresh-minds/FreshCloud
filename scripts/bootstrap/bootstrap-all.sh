#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/bootstrap.env}"
INVENTORY_FILE="${2:-${SCRIPT_DIR}/ansible/inventory/hosts.ini}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file not found: ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

"${SCRIPT_DIR}/bootstrap-rke2.sh" "${ENV_FILE}" "${INVENTORY_FILE}"
"${SCRIPT_DIR}/configure-kubectl.sh" "${ENV_FILE}"

KUBECONFIG_OUTPUT="${KUBECONFIG_OUTPUT:-${HOME}/.kube/freshcloud.yaml}"
KUBECONFIG_OUTPUT="${KUBECONFIG_OUTPUT/#\~/${HOME}}"
export KUBECONFIG="${KUBECONFIG_OUTPUT}"

"${SCRIPT_DIR}/label-and-taint-nodes.sh" "${ENV_FILE}"
"${SCRIPT_DIR}/install-addons.sh" "${ENV_FILE}"

if [[ "${BOOTSTRAP_ARGOCD:-true}" == "true" ]]; then
  "${SCRIPT_DIR}/bootstrap-argocd.sh" "${ENV_FILE}"
fi

"${SCRIPT_DIR}/cluster-health.sh"

echo "End-to-end bootstrap complete."
