# Health Scripts (Pi)

## Work Item Contract
- Inputs: A configured Raspberry Pi host and optional `scripts/pi-bootstrap/pi.env`.
- Outputs: Repeatable health check output for phase-1 controls.
- Acceptance Criteria: Script exits 0 when mandatory checks pass and non-zero on failures.
- How to Verify: Run `scripts/health/pi-phase1-health.sh` and inspect the status lines.

## Available Script
- `pi-phase1-health.sh`: validates SSH, firewall, fail2ban, NTP, Tailscale, and expected hostname.
