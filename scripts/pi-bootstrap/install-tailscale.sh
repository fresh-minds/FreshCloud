#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

ENV_FILE="${1:-${SCRIPT_DIR}/pi.env}"
load_env "${ENV_FILE}"
require_root

require_cmd curl

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

systemctl enable --now tailscaled

if [[ -z "${TAILSCALE_AUTH_KEY:-}" ]]; then
  echo "TAILSCALE_AUTH_KEY is empty. Skipping non-interactive tailscale up."
  echo "Run manually on the Pi when ready:"
  echo "  sudo tailscale up --hostname=${TAILSCALE_HOSTNAME:-freshcloud-pi5} --ssh"
  exit 0
fi

args=(
  "--auth-key=${TAILSCALE_AUTH_KEY}"
  "--hostname=${TAILSCALE_HOSTNAME:-freshcloud-pi5}"
)

if [[ "${TAILSCALE_ENABLE_SSH:-true}" == "true" ]]; then
  args+=("--ssh")
fi

if [[ "${TAILSCALE_ACCEPT_ROUTES:-true}" == "true" ]]; then
  args+=("--accept-routes")
fi

if [[ -n "${TAILSCALE_TAGS:-}" ]]; then
  args+=("--advertise-tags=${TAILSCALE_TAGS}")
fi

tailscale up "${args[@]}"

echo "Tailscale setup completed."
