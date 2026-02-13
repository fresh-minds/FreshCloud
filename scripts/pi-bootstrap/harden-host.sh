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
  ufw fail2ban unattended-upgrades open-iscsi nfs-common iptables arptables ebtables socat conntrack

# Kubernetes nodes should run without swap.
swapoff -a || true
if grep -qE '^[^#].*\sswap\s' /etc/fstab; then
  cp /etc/fstab "/etc/fstab.pre-freshcloud.$(date -u +%Y%m%dT%H%M%SZ)"
  sed -ri '/\sswap\s/s/^/#/' /etc/fstab
fi

cat > /etc/modules-load.d/k8s.conf <<'CFG'
overlay
br_netfilter
CFG

modprobe overlay || true
modprobe br_netfilter || true

cat > /etc/sysctl.d/99-kubernetes.conf <<'CFG'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
vm.swappiness = 10
CFG

sysctl --system >/dev/null

if [[ "${ENABLE_UFW:-true}" == "true" ]]; then
  ufw default deny incoming
  ufw default allow outgoing

  split_csv "${ALLOWED_SSH_CIDRS:-}" ALLOWLIST
  if [[ "${#ALLOWLIST[@]}" -eq 0 || -z "${ALLOWLIST[0]}" ]]; then
    ufw allow 22/tcp
  else
    for cidr in "${ALLOWLIST[@]}"; do
      [[ -z "${cidr}" ]] && continue
      ufw allow from "${cidr}" to any port 22 proto tcp
    done
  fi

  ufw --force enable
fi

if [[ "${ENABLE_FAIL2BAN:-true}" == "true" ]]; then
  cat > /etc/fail2ban/jail.d/sshd.local <<'CFG'
[sshd]
enabled = true
maxretry = 6
bantime = 1h
findtime = 10m
CFG
  systemctl enable --now fail2ban
fi

if [[ "${ENABLE_UNATTENDED_UPGRADES:-true}" == "true" ]]; then
  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CFG'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CFG
fi

timedatectl set-ntp true

BACKUP_BASE_DIR="${BACKUP_BASE_DIR:-/var/lib/freshcloud/backups}"
install -d -m 750 "${BACKUP_BASE_DIR}/postgres"
install -d -m 750 "${BACKUP_BASE_DIR}/minio"

cat > /etc/logrotate.d/freshcloud-backups <<CFG
${BACKUP_BASE_DIR}/*.log {
  daily
  rotate 14
  missingok
  notifempty
  compress
  delaycompress
}
CFG

echo "Host hardening completed."
