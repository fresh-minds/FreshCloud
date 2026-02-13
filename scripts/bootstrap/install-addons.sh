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

for cmd in kubectl helm; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

: "${METALLB_IP_POOL:?METALLB_IP_POOL must be set in ${ENV_FILE}}"
: "${METALLB_POOL_NAME:=public}"
: "${LONGHORN_DEFAULT_REPLICA_COUNT:=2}"

helm repo add metallb https://metallb.github.io/metallb --force-update
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
helm repo add longhorn https://charts.longhorn.io --force-update
helm repo update

helm upgrade --install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace \
  --wait \
  --timeout 10m

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ${METALLB_POOL_NAME}
  namespace: metallb-system
spec:
  addresses:
    - ${METALLB_IP_POOL}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: ${METALLB_POOL_NAME}
  namespace: metallb-system
spec:
  ipAddressPools:
    - ${METALLB_POOL_NAME}
EOF

ingress_args=(
  --namespace ingress-nginx
  --create-namespace
  --wait
  --timeout 10m
  --set controller.replicaCount=2
  --set controller.service.type=LoadBalancer
  --set controller.service.externalTrafficPolicy=Local
  --set-string "controller.service.annotations.metallb\\.universe\\.tf/address-pool=${METALLB_POOL_NAME}"
)

if [[ -n "${INGRESS_LOADBALANCER_IP:-}" ]]; then
  ingress_args+=(--set-string "controller.service.loadBalancerIP=${INGRESS_LOADBALANCER_IP}")
fi

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx "${ingress_args[@]}"

longhorn_args=(
  --namespace longhorn-system
  --create-namespace
  --wait
  --timeout 15m
  --set "defaultSettings.defaultReplicaCount=${LONGHORN_DEFAULT_REPLICA_COUNT}"
)

if [[ -n "${LONGHORN_BACKUP_TARGET:-}" ]]; then
  longhorn_args+=(--set-string "defaultSettings.backupTarget=${LONGHORN_BACKUP_TARGET}")
fi

if [[ -n "${LONGHORN_BACKUP_SECRET:-}" ]]; then
  longhorn_args+=(--set-string "defaultSettings.backupTargetCredentialSecret=${LONGHORN_BACKUP_SECRET}")
fi

helm upgrade --install longhorn longhorn/longhorn "${longhorn_args[@]}"

kubectl patch storageclass longhorn \
  --type merge \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

if kubectl get storageclass local-path >/dev/null 2>&1; then
  kubectl patch storageclass local-path \
    --type merge \
    -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
fi

echo "Baseline add-ons installed: MetalLB, ingress-nginx, Longhorn."
