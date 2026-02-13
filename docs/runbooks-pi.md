# Raspberry Pi Runbooks (Phase 1 Scaffold)

## Work Item Contract
- Inputs: `docs/raspberry-pi-k8s-plan.md`, Raspberry Pi 5 with Ubuntu 24.04 LTS, and `scripts/pi-bootstrap/pi.env`.
- Outputs: Day-0 provisioning, day-1 health checks, and day-2 maintenance procedures for phase 1 (`P-01` to `P-03`).
- Acceptance Criteria: A second engineer can bootstrap and validate host readiness and private remote access without tribal knowledge.
- How to Verify: Execute every command in this runbook and capture command output artifacts for each verification gate.

## Day-0 Provisioning (Phase 1)
| Step | Inputs | Outputs | Acceptance Criteria | How to Verify |
|---|---|---|---|---|
| PI-D0-1 Prepare environment file | `scripts/pi-bootstrap/pi.env.example`, local SSH public key | `scripts/pi-bootstrap/pi.env` with site-specific values | All mandatory values are set and no secrets are committed to Git | `test -f scripts/pi-bootstrap/pi.env` and `git status --short` does not include secret files |
| PI-D0-2 Host preparation | `pi.env`, sudo access on Pi | Hostname, SSH key auth, optional static netplan file | SSH key-only auth works and hostname matches expected value | `hostnamectl`, `sudo sshd -t`, and remote key-based SSH login test |
| PI-D0-3 Host hardening | Prepared host from PI-D0-2 | Firewall, fail2ban, unattended upgrades, Kubernetes sysctls | Required security services are active and kernel params are applied | `sudo ufw status`, `sudo systemctl status fail2ban`, `sudo sysctl net.ipv4.ip_forward` |
| PI-D0-4 Private remote access | Tailscale auth key (or interactive login) | Pi joined to tailnet and reachable from remote network | SSH access over Tailscale IP succeeds without opening router ports | From external network: `ssh <user>@100.x.y.z` |
| PI-D0-5 Health verification | Completed PI-D0-1..PI-D0-4 | Health report from scripted checks | Script reports all mandatory checks as OK | `scripts/health/pi-phase1-health.sh scripts/pi-bootstrap/pi.env` |

## Day-0 Commands
```bash
cp /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/pi-bootstrap/pi.env.example \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/pi-bootstrap/pi.env

$EDITOR /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/pi-bootstrap/pi.env

sudo /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/pi-bootstrap/bootstrap-phase1.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/pi-bootstrap/pi.env

/Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/health/pi-phase1-health.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/pi-bootstrap/pi.env
```

## Day-1 Operations
| Routine | Inputs | Outputs | Acceptance Criteria | How to Verify |
|---|---|---|---|---|
| PI-D1-1 Daily host health check | Access to Pi and env file | Daily health status evidence | No failed checks for SSH, firewall, fail2ban, tailscale | Run `scripts/health/pi-phase1-health.sh` and archive output |
| PI-D1-2 Package/security patch check | Ubuntu package metadata | Up-to-date package baseline | No pending high-priority security upgrades | `sudo apt update && apt list --upgradable` |
| PI-D1-3 Tailscale access review | Tailscale admin console | Updated trusted-device/access list | Unknown devices removed and access policy current | Verify tailnet device list and ACL/tag policy |

## Day-2 Maintenance and Incident Procedures
| Procedure | Inputs | Outputs | Acceptance Criteria | How to Verify |
|---|---|---|---|---|
| PI-D2-1 Monthly reboot test | Maintenance window | Verified clean boot and service recovery | SSH, fail2ban, ufw, tailscale active after reboot | `sudo reboot`, then rerun health script |
| PI-D2-2 Remote access outage triage | Failed remote access alert | Root cause and mitigation actions | Access restored or fallback path documented | Check local LAN SSH, tailscaled logs, and router connectivity |
| PI-D2-3 Backup scaffold smoke test | `scripts/backup/backup.env` and tools | Validated backup artifact pipeline | Backup scripts run and smoke test passes | Run `postgres-backup.sh`, `minio-backup.sh`, `restore-smoke-test.sh` |

## Incident Quick Checks
- `sudo systemctl status ssh`
- `sudo systemctl status tailscaled`
- `sudo journalctl -u tailscaled --since "-30m"`
- `sudo ufw status verbose`
- `ip a`

## Exit Criteria for Phase 1
- Pi is reachable through Tailscale from a remote network.
- Password SSH login is disabled and key-based access is operational.
- Baseline hardening controls are active and validated by scripted checks.
