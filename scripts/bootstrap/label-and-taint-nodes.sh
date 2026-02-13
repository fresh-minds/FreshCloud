#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/bootstrap.env}"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required." >&2
  exit 1
fi

: "${CLUSTER_NAME:=freshcloud-mvp}"
: "${LEASEWEB_REGION:=leaseweb-eu}"
: "${REMOVE_CONTROL_PLANE_TAINTS:=true}"
: "${INGRESS_NODE:=}"
: "${INGRESS_NODE_TAINT:=}"

kubectl label nodes --all "freshcloud.io/cluster=${CLUSTER_NAME}" --overwrite
kubectl label nodes --all "topology.kubernetes.io/region=${LEASEWEB_REGION}" --overwrite
kubectl label nodes --all "freshcloud.io/storage=longhorn" --overwrite

if [[ "${REMOVE_CONTROL_PLANE_TAINTS}" == "true" ]]; then
  while IFS= read -r node; do
    kubectl taint node "${node}" node-role.kubernetes.io/control-plane- >/dev/null 2>&1 || true
    kubectl taint node "${node}" node-role.kubernetes.io/master- >/dev/null 2>&1 || true
  done < <(kubectl get nodes -o name | cut -d/ -f2)
fi

if [[ -n "${INGRESS_NODE}" ]]; then
  kubectl label node "${INGRESS_NODE}" freshcloud.io/ingress=true --overwrite
fi

if [[ -n "${INGRESS_NODE_TAINT}" ]]; then
  if [[ -z "${INGRESS_NODE}" ]]; then
    echo "INGRESS_NODE must be set when INGRESS_NODE_TAINT is set." >&2
    exit 1
  fi
  kubectl taint node "${INGRESS_NODE}" "${INGRESS_NODE_TAINT}" --overwrite
fi

echo "Node labeling/taint policy applied."
