#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

ENV_FILE="${1:-${SCRIPT_DIR}/pi.env}"
load_env "${ENV_FILE}"
require_root

require_cmd apt-get

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg jq openssh-server netplan.io

if [[ -n "${PI_HOSTNAME:-}" ]]; then
  hostnamectl set-hostname "${PI_HOSTNAME}"
fi

if [[ -z "${ADMIN_USER:-}" ]]; then
  echo "ADMIN_USER is required." >&2
  exit 1
fi

if ! id "${ADMIN_USER}" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "${ADMIN_USER}"
fi

SSH_PUBLIC_KEY_PATH="$(expand_path "${SSH_PUBLIC_KEY_PATH:-}")"
if [[ -n "${SSH_PUBLIC_KEY_PATH}" ]]; then
  if [[ ! -f "${SSH_PUBLIC_KEY_PATH}" ]]; then
    echo "SSH public key not found: ${SSH_PUBLIC_KEY_PATH}" >&2
    exit 1
  fi

  install -d -m 700 "/home/${ADMIN_USER}/.ssh"
  touch "/home/${ADMIN_USER}/.ssh/authorized_keys"

  if ! grep -Fxq "$(cat "${SSH_PUBLIC_KEY_PATH}")" "/home/${ADMIN_USER}/.ssh/authorized_keys"; then
    cat "${SSH_PUBLIC_KEY_PATH}" >> "/home/${ADMIN_USER}/.ssh/authorized_keys"
  fi

  chmod 600 "/home/${ADMIN_USER}/.ssh/authorized_keys"
  chown -R "${ADMIN_USER}:${ADMIN_USER}" "/home/${ADMIN_USER}/.ssh"
fi

if [[ "${SSH_DISABLE_PASSWORD_AUTH:-true}" == "true" ]]; then
  cat > /etc/ssh/sshd_config.d/60-freshcloud-hardening.conf <<'CFG'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
PubkeyAuthentication yes
CFG

  systemctl reload ssh >/dev/null 2>&1 || systemctl reload sshd >/dev/null 2>&1 || true
fi

PI_NETPLAN_FILE="${PI_NETPLAN_FILE:-/etc/netplan/99-freshcloud.yaml}"
if [[ -n "${PI_STATIC_IP_CIDR:-}" && -n "${PI_GATEWAY_IP:-}" && -n "${PI_INTERFACE:-}" ]]; then
  split_csv "${PI_DNS_SERVERS:-1.1.1.1,1.0.0.1}" DNS_SERVERS
  dns_line=""
  if [[ "${#DNS_SERVERS[@]}" -gt 0 ]]; then
    dns_line="$(printf '%s, ' "${DNS_SERVERS[@]}")"
    dns_line="${dns_line%, }"
  fi

  cat > "${PI_NETPLAN_FILE}" <<CFG
network:
  version: 2
  ethernets:
    ${PI_INTERFACE}:
      dhcp4: false
      addresses: [${PI_STATIC_IP_CIDR}]
      routes:
        - to: default
          via: ${PI_GATEWAY_IP}
      nameservers:
        addresses: [${dns_line}]
CFG

  if [[ "${APPLY_NETWORK_CHANGES:-false}" == "true" ]]; then
    netplan generate
    netplan apply
  else
    echo "Netplan file written to ${PI_NETPLAN_FILE}."
    echo "Set APPLY_NETWORK_CHANGES=true to apply it automatically."
  fi
fi

echo "Host preparation completed."
