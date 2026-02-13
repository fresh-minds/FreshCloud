#!/usr/bin/env bash
set -euo pipefail

TF_ENV_DIR="${1:-infra/terraform/leaseweb/envs/mvp}"
OUT_FILE="${2:-infra/ansible/inventories/mvp/hosts.generated.yml}"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

MODEL_JSON="$(terraform -chdir="${TF_ENV_DIR}" output -json ansible_inventory_model)"

mkdir -p "$(dirname "${OUT_FILE}")"

BASTION_NAME="$(jq -r '.bastion_host' <<<"${MODEL_JSON}")"
BASTION_IP="$(jq -r --arg n "${BASTION_NAME}" '.hosts[$n].ansible_host' <<<"${MODEL_JSON}")"
PROXYJUMP="$(jq -r '.proxyjump' <<<"${MODEL_JSON}")"

{
  cat <<HEADER
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/freshcloud_id_ed25519
    bastion_host: ${BASTION_IP}
    ansible_ssh_common_args: "-o ProxyJump=${PROXYJUMP}"
  children:
    access:
      hosts:
HEADER

  jq -r '
    .hosts
    | to_entries[]
    | select(.value.role == "access")
    | "        \(.key):\n          ansible_host: \(.value.ansible_host)\n          private_ip: \(.value.private_ip)\n          ansible_ssh_common_args: \"\""
  ' <<<"${MODEL_JSON}"

  cat <<'MIDDLE'
    edge:
      hosts:
MIDDLE

  jq -r '
    .hosts
    | to_entries[]
    | select(.value.role == "edge")
    | "        \(.key):\n          ansible_host: \(.value.ansible_host)\n          private_ip: \(.value.private_ip)"
  ' <<<"${MODEL_JSON}"

  cat <<'FOOTER'
    k8s:
      hosts:
FOOTER

  jq -r '
    .hosts
    | to_entries[]
    | select(.value.role == "k8s")
    | "        \(.key):\n          ansible_host: \(.value.ansible_host)\n          private_ip: \(.value.private_ip)"
  ' <<<"${MODEL_JSON}"
} >"${OUT_FILE}"

echo "Generated ${OUT_FILE} from ${TF_ENV_DIR}" >&2
