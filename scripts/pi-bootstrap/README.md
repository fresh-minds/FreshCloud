# Raspberry Pi Phase 1 Bootstrap Scripts

## Work Item Contract
- Inputs: A fresh Ubuntu Server 24.04 Raspberry Pi 5 host and `scripts/pi-bootstrap/pi.env` values.
- Outputs: Host prepared, hardened, and connected to Tailscale for private remote administration.
- Acceptance Criteria: SSH key auth works, baseline services are active, and the host is reachable over Tailscale.
- How to Verify: Run `scripts/health/pi-phase1-health.sh` and confirm all checks pass.

## Scripts
- `prepare-host.sh`: base OS prep, SSH hardening, optional static IP netplan file generation.
- `harden-host.sh`: firewall, fail2ban, unattended upgrades, Kubernetes kernel params.
- `install-tailscale.sh`: installs and connects Tailscale.
- `bootstrap-phase1.sh`: orchestrates all phase-1 steps.
- `pi.env.example`: required variables template.

## Quick Start
```bash
cp scripts/pi-bootstrap/pi.env.example scripts/pi-bootstrap/pi.env
$EDITOR scripts/pi-bootstrap/pi.env
sudo scripts/pi-bootstrap/bootstrap-phase1.sh scripts/pi-bootstrap/pi.env
scripts/health/pi-phase1-health.sh scripts/pi-bootstrap/pi.env
```

## Safety Defaults
- Network changes are rendered to a netplan file but are not applied unless `APPLY_NETWORK_CHANGES=true`.
- Tailscale auth is skipped if `TAILSCALE_AUTH_KEY` is empty.
