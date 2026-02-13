#!/usr/bin/env bash
set -euo pipefail

TIMEOUT_SECONDS="${HEALTH_TIMEOUT_SECONDS:-600}"
RUN_PVC_SMOKE_TEST="${RUN_PVC_SMOKE_TEST:-true}"
SMOKE_NAMESPACE="${SMOKE_NAMESPACE:-bootstrap-smoke}"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required." >&2
  exit 1
fi

cleanup_smoke_namespace() {
  kubectl delete namespace "${SMOKE_NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
}

kubectl wait --for=condition=Ready nodes --all --timeout="${TIMEOUT_SECONDS}s"
kubectl get nodes -o wide

if kubectl -n kube-system get ds rke2-canal >/dev/null 2>&1; then
  kubectl -n kube-system rollout status ds/rke2-canal --timeout="${TIMEOUT_SECONDS}s"
fi

if kubectl -n kube-system get ds rke2-cilium >/dev/null 2>&1; then
  kubectl -n kube-system rollout status ds/rke2-cilium --timeout="${TIMEOUT_SECONDS}s"
fi

if kubectl get namespace metallb-system >/dev/null 2>&1; then
  kubectl -n metallb-system wait deployment --all --for=condition=Available --timeout="${TIMEOUT_SECONDS}s"
  kubectl -n metallb-system get pods
  kubectl get ipaddresspools.metallb.io -n metallb-system
fi

if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
  kubectl -n ingress-nginx wait deployment --all --for=condition=Available --timeout="${TIMEOUT_SECONDS}s"
  kubectl -n ingress-nginx get pods
  kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide

  ingress_ip="$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  ingress_hostname="$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [[ -z "${ingress_ip}" && -z "${ingress_hostname}" ]]; then
    echo "ingress-nginx-controller has no external LoadBalancer address." >&2
    exit 1
  fi
fi

if kubectl get namespace longhorn-system >/dev/null 2>&1; then
  kubectl -n longhorn-system wait deployment --all --for=condition=Available --timeout="${TIMEOUT_SECONDS}s"
  kubectl -n longhorn-system get pods
fi

if kubectl get storageclass longhorn >/dev/null 2>&1; then
  is_default="$(kubectl get storageclass longhorn -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null || true)"
  if [[ "${is_default}" != "true" ]]; then
    echo "StorageClass longhorn is not marked as default." >&2
    exit 1
  fi
fi

if kubectl get namespace argocd >/dev/null 2>&1; then
  kubectl -n argocd wait deployment --all --for=condition=Available --timeout="${TIMEOUT_SECONDS}s"
  kubectl -n argocd get pods
fi

if [[ "${RUN_PVC_SMOKE_TEST}" == "true" ]]; then
  trap cleanup_smoke_namespace EXIT
  cleanup_smoke_namespace

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${SMOKE_NAMESPACE}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: smoke-pvc
  namespace: ${SMOKE_NAMESPACE}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: smoke-writer
  namespace: ${SMOKE_NAMESPACE}
spec:
  containers:
    - name: busybox
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - mountPath: /data
          name: data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: smoke-pvc
EOF

  kubectl -n "${SMOKE_NAMESPACE}" wait pvc/smoke-pvc --for=jsonpath='{.status.phase}'=Bound --timeout=180s
  kubectl -n "${SMOKE_NAMESPACE}" wait pod/smoke-writer --for=condition=Ready --timeout=180s
  kubectl -n "${SMOKE_NAMESPACE}" exec smoke-writer -- sh -c "echo freshcloud-ok > /data/probe && grep -q freshcloud-ok /data/probe"
  kubectl delete namespace "${SMOKE_NAMESPACE}" --wait=true
  trap - EXIT
fi

echo "Cluster health verification passed."
