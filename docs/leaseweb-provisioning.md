# Leaseweb Provisioning Layout and Checklist (MVP)

## Work Item Contract
- Inputs: `AGENTS.md` MVP scope, `docs/architecture-mvp.md`, and requirement for exact Leaseweb provisioning with least-privilege boundaries.
- Outputs: Server and network layout, public/private IP plan, firewall and access model, load balancing assumptions, DNS/TLS ownership boundaries, and a step-by-step provisioning checklist.
- Acceptance Criteria: Another engineer can provision the exact Leaseweb servers and networking using only this document and can apply the security boundary model without tribal knowledge.
- How to Verify: Execute the full checklist in a clean Leaseweb project and confirm all verification steps pass.

## 1. MVP Infrastructure Layout (Leaseweb)

### 1.1 Server Sizing and Count
This is the exact MVP footprint for production-like operation without over-engineering.

| Hostname | Count | Role | vCPU | RAM | OS Disk | Data Disk | NICs |
|---|---:|---|---:|---:|---:|---:|---|
| `fc-mvp-euw1-k8s-01` | 1 | RKE2 server + worker | 8 | 32 GB | 100 GB | 500 GB (Longhorn) | Private only |
| `fc-mvp-euw1-k8s-02` | 1 | RKE2 server + worker | 8 | 32 GB | 100 GB | 500 GB (Longhorn) | Private only |
| `fc-mvp-euw1-k8s-03` | 1 | RKE2 server + worker | 8 | 32 GB | 100 GB | 500 GB (Longhorn) | Private only |
| `fc-mvp-euw1-edge-01` | 1 | Edge LB (HAProxy + Keepalived) | 2 | 4 GB | 40 GB | n/a | Public + private |
| `fc-mvp-euw1-edge-02` | 1 | Edge LB (HAProxy + Keepalived) | 2 | 4 GB | 40 GB | n/a | Public + private |
| `fc-mvp-euw1-access-01` | 1 | Bastion + WireGuard | 2 | 4 GB | 40 GB | n/a | Public + private |

Sizing assumptions:
- Kubernetes nodes are intentionally symmetric for simple operations and predictable failure handling.
- Longhorn uses the dedicated 500 GB data disk on each Kubernetes node (do not place Longhorn data on OS disk).
- Edge LBs terminate no app TLS; they pass `80/443` through to in-cluster ingress NodePorts.

### 1.2 Network and VLAN Assumptions
- One Leaseweb private VLAN for all internal east-west and management traffic.
- VLAN name: `fc-mvp-euw1-pri-vlan`
- Private CIDR: `10.40.0.0/24`
- Public addressing: one Leaseweb routed public `/29` block (5 usable IPs minimum).
- Region: single region (`euw1` placeholder; replace with exact Leaseweb region code in Terraform vars).

### 1.3 IP Plan (Public + Private)
Private VLAN static assignments:

| Endpoint | Private IP | Notes |
|---|---|---|
| `fc-mvp-euw1-k8s-01` | `10.40.0.10` | RKE2, etcd member |
| `fc-mvp-euw1-k8s-02` | `10.40.0.11` | RKE2, etcd member |
| `fc-mvp-euw1-k8s-03` | `10.40.0.12` | RKE2, etcd member |
| `fc-mvp-euw1-edge-01` | `10.40.0.20` | HAProxy backend node |
| `fc-mvp-euw1-edge-02` | `10.40.0.21` | HAProxy backend node |
| `fc-mvp-euw1-access-01` | `10.40.0.30` | Bastion + WireGuard endpoint |

Public block allocation rules (replace with actual addresses from Leaseweb):

| Purpose | Public IP Symbol | Assigned To |
|---|---|---|
| Bastion/WireGuard endpoint | `PUB_IP_1` | `fc-mvp-euw1-access-01` |
| Edge node direct mgmt (restricted) | `PUB_IP_2` | `fc-mvp-euw1-edge-01` |
| Edge node direct mgmt (restricted) | `PUB_IP_3` | `fc-mvp-euw1-edge-02` |
| Public ingress virtual IP (VIP) | `PUB_IP_4` | Keepalived floating VIP (`edge-01`/`edge-02`) |

Kubernetes internal ranges (for consistency in bootstrap):
- Pod CIDR: `10.42.0.0/16`
- Service CIDR: `10.43.0.0/16`

## 2. Security Boundaries and Least-Privilege Access

### 2.1 Boundary Model
| Boundary | Trust Level | Allowed Inbound | Owner |
|---|---|---|---|
| Internet -> Edge VIP (`PUB_IP_4`) | Untrusted | `TCP 80,443` only | Platform Ops |
| Internet -> Bastion (`PUB_IP_1`) | Restricted | `UDP 51820` from admin CIDRs, `TCP 22` from admin CIDRs only | Platform Ops |
| Internet -> Edge direct IPs (`PUB_IP_2`,`PUB_IP_3`) | Restricted | No public app traffic; `TCP 22` only from WireGuard subnet | Platform Ops |
| Public -> Kubernetes nodes | Denied | None | Platform Ops |
| WireGuard subnet -> private VLAN | Trusted admin | `TCP 22`, `TCP 6443`, monitoring and ops ports as required | Platform Ops |
| East-west inside cluster | Semi-trusted | Default-deny NetworkPolicy; allow explicit namespace/service flows only | Security + Kubernetes |

### 2.2 Firewall Model (Three Layers)
1. Leaseweb network firewall (north-south guardrail):
   - Default deny inbound.
   - Allow exact inbound ports listed in boundary model.
   - Deny inbound to Kubernetes node public interfaces (none should exist).
2. Host firewall on every VM (`nftables` or `ufw`):
   - Default deny inbound.
   - Edge nodes only allow `80/443`, health checks from private VLAN, and SSH from WireGuard subnet.
   - Kubernetes nodes only allow Kubernetes-required ports from private VLAN.
3. Kubernetes NetworkPolicies (east-west guardrail):
   - Default deny per namespace.
   - Explicit allow for ingress controller, monitoring, MinIO, Postgres, and DNS.

## 3. Load Balancing Approach (Assumptions)

Selected MVP approach:
- Two dedicated edge VMs run HAProxy + Keepalived.
- `PUB_IP_4` floats between `edge-01` and `edge-02`.
- HAProxy forwards:
  - `80 -> NodePort 30080` on `10.40.0.10-12`
  - `443 -> NodePort 30443` on `10.40.0.10-12`
- TLS certificates are managed inside Kubernetes by cert-manager on NGINX ingress.
- Day-0 standard: use this edge pattern, not public-IP MetalLB advertisement, until Leaseweb confirms routed/L2 behavior for that model.

Assumptions:
- Leaseweb allows failover/floating IP movement between `edge-01` and `edge-02`.
- VRRP/health-check traffic is allowed between edge nodes on private VLAN.

Fallback if floating IP is unavailable:
- Bind `PUB_IP_4` to one edge node and document ingress as single-edge risk until provider confirmation.

## 4. Remote Access Approach (Bastion + WireGuard)
- All operator access starts through WireGuard on `fc-mvp-euw1-access-01`.
- SSH to any private host is only allowed from WireGuard subnet (example `10.99.0.0/24`).
- Kubernetes API (`6443`) is private; accessed through WireGuard or SSH tunnel from bastion.
- Break-glass local admin on hosts is disabled after bootstrap (except documented emergency user with rotated credentials).
- Bastion has no workload runtimes (no Docker/Kubernetes components).

## 5. DNS and TLS Ownership Boundaries
| Area | System of Record | Change Path | Owner |
|---|---|---|---|
| Domain registration + zone authority | External DNS provider (recommended) | Manual admin + audited PR process | Platform Lead |
| `A/AAAA` records for app endpoints | External DNS provider | Git-tracked change request + DNS API apply | Platform Ops |
| Reverse DNS (PTR) for public IPs | Leaseweb | Leaseweb portal/API | Leaseweb Infra Engineer |
| TLS issuance for app endpoints | cert-manager + Let's Encrypt | GitOps manifests (`ClusterIssuer`, `Certificate`) | Kubernetes Engineer |
| TLS secrets in cluster | Kubernetes namespaces | cert-manager managed | Kubernetes Engineer |

Rules:
- DNS API tokens are stored via SOPS/External Secrets; never plaintext in Git.
- Wildcard certs (`*.env.example.com`) use DNS-01 if DNS API automation is available.
- If DNS API automation is unavailable, use HTTP-01 on `PUB_IP_4` with strict runbook steps.

## 6. Exact Leaseweb Provisioning Checklist

| Step | Inputs | Outputs | Acceptance Criteria | How to Verify |
|---|---|---|---|---|
| P-01 Create Leaseweb project and IAM roles | Leaseweb account, team member list, MFA policy | Dedicated project, least-privilege roles (`billing`, `ops`, `readonly`) | No shared root account usage; all users have MFA | Attempt login without MFA fails; role matrix documented |
| P-02 Reserve networking primitives | Target region, `/24` private CIDR, public `/29` requirement | Private VLAN `fc-mvp-euw1-pri-vlan`, public IP block, ingress VIP reservation | VLAN active; 5+ usable public IPs available | Portal/API shows VLAN and reserved IPs |
| P-03 Define baseline firewall policy | Approved source CIDRs for admins, required inbound ports | Leaseweb firewall policy attached to all servers | Default deny inbound with explicit allowlist only | External port scan sees only expected ports (`22`, `51820`, `80`, `443`) |
| P-04 Provision bastion/WireGuard host | Host spec for `fc-mvp-euw1-access-01`, `PUB_IP_1`, `10.40.0.30` | Running bastion with dual NIC and hardened SSH | WireGuard handshake works; SSH to bastion only from allowed CIDRs | `wg show` has active peers; failed SSH from unauthorized IP |
| P-05 Provision edge nodes | Host specs for `edge-01`, `edge-02`; `PUB_IP_2`,`PUB_IP_3`; private IPs | Two edge nodes running on public+private networks | Both nodes reachable from bastion and can reach private Kubernetes subnet | SSH from bastion succeeds; private ping to planned node IPs works |
| P-06 Configure edge HA + VIP | `PUB_IP_4`, Keepalived/HAProxy configs, Kubernetes backend targets | Floating VIP with active/standby failover and LB listeners `80/443` | Failover between edge nodes <30 seconds; health checks route to healthy backends only | Stop HAProxy on active node and confirm VIP/traffic shifts |
| P-07 Provision Kubernetes nodes | 3 node specs, private IP map, OS image baseline | `k8s-01..03` provisioned with private-only networking and attached data disks | No public exposure; private reachability from bastion and edge | Internet scan cannot reach nodes; SSH from bastion works |
| P-08 Apply host hardening baseline | OS hardening script/Ansible role, SSH keys, time sync, auditd | Hardened hosts with least-privilege defaults | Password SSH disabled; required packages and audit settings present | `sshd -T` confirms no password auth; auditd active |
| P-09 Export inventory for bootstrap | Final IP mapping, hostnames, SSH bastion config | `infra/ansible/inventories/mvp/hosts.yml` values ready | Inventory matches provisioned assets exactly | Cross-check inventory against Leaseweb API output |
| P-10 Validate end-to-end network paths | Firewall rules, host firewalls, edge config | Confirmed ingress path + admin path + internal isolation | Public traffic only via VIP; admin traffic only via WireGuard/bastion | `curl` to VIP works; direct node access from internet blocked |
| P-11 Hand off to Kubernetes bootstrap | Completed infra checklist and inventory | Signed day-0 infra handoff to platform bootstrap | Platform engineer can start RKE2 bootstrap without infra clarifications | Bootstrap dry-run reaches all nodes and retrieves facts |

## 7. To Verify with Leaseweb
- [ ] Exact API coverage for VLAN creation, routed/floating IP assignment, and firewall rule management.
- [ ] Whether failover IP movement supports Keepalived/VRRP-style operations in chosen product tier.
- [ ] Whether Leaseweb supports a production-safe MetalLB public IP advertisement model (BGP or L2) if we later simplify edge design.
- [ ] Limits on private VLAN count, subnet sizing, and cross-project attach rules.
- [ ] Any anti-spoofing requirements for VIP assignment on edge nodes.
- [ ] DDoS protection scope and what traffic classes are auto-mitigated versus paid add-ons.
- [ ] Throughput or PPS limits per VM tier that could bottleneck edge nodes.
- [ ] Whether reverse DNS (PTR) is fully API-manageable for automation.
- [ ] Snapshot/backups feature availability and restore SLAs for each VM product line.
- [ ] Outbound traffic billing model (especially object-storage backup egress paths).
- [ ] Maintenance window notifications and live-migration behavior for VM hosts.

## 8. Final Provisioning Definition of Done
- All six hosts exist with exact names, sizes, and IP mappings in this document.
- Public access is limited to ingress VIP (`80/443`) and bastion (`22/51820` from allowlisted CIDRs).
- Kubernetes nodes have no public ingress path.
- Edge VIP failover is tested and documented.
- Handoff inventory is complete and consumed by bootstrap automation.
