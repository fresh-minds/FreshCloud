# Raspberry Pi To Verify Checklist

## Work Item Contract
- Inputs: Raspberry Pi plan assumptions and local home-network constraints.
- Outputs: Resolved infrastructure assumptions and recorded decisions for production-safe operation.
- Acceptance Criteria: Every checklist item is either verified with evidence or documented as an accepted risk.
- How to Verify: Link each item to command output, screenshot, or a dated decision note.

## Checklist
- [ ] Storage reliability: verify SSD power and sustained I/O stability under load.
- [ ] Network reality: confirm CGNAT vs direct public IPv4 availability.
- [ ] DNS ownership: confirm control over a domain for remote ingress naming.
- [ ] Power resilience: validate UPS runtime and graceful shutdown behavior.
- [ ] Bandwidth baseline: confirm upload throughput is sufficient for expected traffic.
- [ ] Backup target: confirm off-device backup destination and credentials lifecycle.
- [ ] Physical security: document where Pi and storage media are located and who has access.
- [ ] Access policy: define who can join tailnet and who can SSH into the server.
- [ ] ISP constraints: verify inbound policy, fair-use limits, and outage handling expectations.

## Evidence Template
| Item | Status | Evidence | Decision Date | Owner |
|---|---|---|---|---|
| Example: Network reality | Verified | `tailscale netcheck` output + ISP docs | 2026-02-13 | Platform owner |
