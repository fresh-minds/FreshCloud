#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/bootstrap.env}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file not found: ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${PRIMARY_NODE_HOST:?PRIMARY_NODE_HOST must be set in ${ENV_FILE}}"
: "${SSH_USER:?SSH_USER must be set in ${ENV_FILE}}"

RKE2_API_HOST="${RKE2_API_HOST:-${PRIMARY_NODE_HOST}}"
KUBECONFIG_OUTPUT="${KUBECONFIG_OUTPUT:-${HOME}/.kube/freshcloud.yaml}"
KUBECONFIG_OUTPUT="${KUBECONFIG_OUTPUT/#\~/${HOME}}"

mkdir -p "$(dirname "${KUBECONFIG_OUTPUT}")"

SSH_ARGS=(-o StrictHostKeyChecking=accept-new)
if [[ -n "${SSH_PRIVATE_KEY:-}" ]]; then
  SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY/#\~/${HOME}}"
  SSH_ARGS+=(-i "${SSH_PRIVATE_KEY}")
fi

ssh "${SSH_ARGS[@]}" "${SSH_USER}@${PRIMARY_NODE_HOST}" "sudo cat /etc/rancher/rke2/rke2.yaml" \
  | sed "s/127.0.0.1/${RKE2_API_HOST}/g" > "${KUBECONFIG_OUTPUT}"

chmod 600 "${KUBECONFIG_OUTPUT}"

echo "Kubeconfig written to ${KUBECONFIG_OUTPUT}"
echo "Run: export KUBECONFIG=${KUBECONFIG_OUTPUT}"
