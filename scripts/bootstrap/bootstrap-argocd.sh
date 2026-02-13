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

: "${ARGOCD_NAMESPACE:=argocd}"
: "${ARGOCD_VERSION:=v2.11.7}"
: "${ARGOCD_ROOT_APP_PATH:=}"

kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n "${ARGOCD_NAMESPACE}" \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

kubectl -n "${ARGOCD_NAMESPACE}" wait deployment --all \
  --for=condition=Available \
  --timeout=10m

if [[ -n "${ARGOCD_ROOT_APP_PATH}" ]]; then
  if [[ -f "${ARGOCD_ROOT_APP_PATH}" ]]; then
    kubectl apply -f "${ARGOCD_ROOT_APP_PATH}"
  else
    echo "ARGOCD_ROOT_APP_PATH does not exist: ${ARGOCD_ROOT_APP_PATH}" >&2
    exit 1
  fi
fi

echo "Argo CD bootstrap complete."
