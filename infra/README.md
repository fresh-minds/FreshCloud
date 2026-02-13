# Infrastructure Management Guide (Leaseweb MVP)

## Work Item Contract
- Inputs: `docs/architecture-mvp.md`, `docs/leaseweb-provisioning.md`, and AGENTS rules for automation-first delivery.
- Outputs: Clear split of manual steps vs IaC, infra execution flow, and naming conventions for all infrastructure artifacts.
- Acceptance Criteria: Any engineer can identify which resources are managed manually versus code, and can name new resources consistently.
- How to Verify: Use this guide during a clean provisioning run and confirm each created resource maps to a declared management path and naming rule.

## 1. Management Model: Manual vs IaC

Principle:
- Manual actions are limited to account/bootstrap prerequisites that cannot be reliably automated on day 0.
- Repeatable infrastructure is managed under `infra/` using Terraform and Ansible.
- Kubernetes resources are managed via Argo CD GitOps after cluster bootstrap.

| Scope | Primary Tool | Location | Manual or IaC | Notes |
|---|---|---|---|---|
| Leaseweb account setup, MFA, billing role assignment | Leaseweb portal | n/a | Manual | One-time prerequisite, audit required. |
| Initial API credential bootstrap | Leaseweb portal | n/a | Manual | Store credentials in secret manager, never in Git. |
| VLAN, IP reservations, and firewall objects | Terraform contract + Leaseweb portal/API | `infra/terraform/leaseweb/` | Hybrid | Managed as code-defined intent plus manual execution until provider coverage is verified. |
| VM provisioning (Public Cloud path) | Terraform | `infra/terraform/leaseweb/` | IaC | Controlled by `enable_instance_creation` gate per environment. |
| OS baseline hardening, users, packages, WireGuard, edge config | Ansible | `infra/ansible/` | IaC | Applied after VM provisioning. |
| Kubernetes bootstrap (RKE2) | Ansible | `infra/ansible/playbooks/` | IaC | Inventory generated from Terraform outputs. |
| Ingress, TLS, storage, data services, observability, security policies | Argo CD (GitOps) | `gitops/` | IaC | Managed in-cluster only via Git. |

## 2. Directory Ownership Under `infra/`

Expected structure:
```text
infra/
├── README.md
├── terraform/
│   └── leaseweb/
│       ├── modules/
│       │   ├── network/
│       │   ├── compute/
│       │   └── security/
│       └── envs/
│           ├── mvp/
│           ├── stage/
│           └── prod/
└── ansible/
    ├── inventories/
    ├── playbooks/
    └── roles/
```

Ownership rules:
- `infra/terraform/leaseweb/envs/*` defines environment-specific desired state.
- `infra/terraform/leaseweb/modules/*` contains reusable modules only.
- `infra/ansible/inventories/*` is generated from Terraform outputs plus explicit host vars.
- `infra/ansible/playbooks/*` is idempotent and safe to rerun.

## 3. Naming Conventions

### 3.1 Global Pattern
Use this pattern for all Leaseweb and automation resources:

`fc-<env>-<region>-<role>-<index>`

Examples:
- `fc-mvp-euw1-k8s-01`
- `fc-mvp-euw1-edge-02`
- `fc-prod-euw1-pri-vlan`

### 3.2 Resource-Specific Rules
| Resource Type | Convention | Example |
|---|---|---|
| VM hostname | `fc-<env>-<region>-<role>-<nn>` | `fc-mvp-euw1-k8s-03` |
| Private VLAN | `fc-<env>-<region>-pri-vlan` | `fc-mvp-euw1-pri-vlan` |
| Firewall policy | `fc-<env>-<region>-fw-<scope>` | `fc-mvp-euw1-fw-edge` |
| Public VIP label | `fc-<env>-<region>-vip-ingress` | `fc-mvp-euw1-vip-ingress` |
| Terraform workspace/env dir | `<env>` | `mvp`, `stage`, `prod` |
| Ansible inventory | `<env>/hosts.yml` | `mvp/hosts.yml` |

### 3.3 Tag/Label Set (Mandatory)
Apply to every supported resource:
- `project=freshcloud`
- `env=<mvp|stage|prod>`
- `region=<leaseweb-region>`
- `owner=platform`
- `managed-by=<terraform|ansible|manual>`
- `criticality=<edge|control-plane|data|access>`

## 4. Infra Execution Flow

| Step | Inputs | Outputs | Acceptance Criteria | How to Verify |
|---|---|---|---|---|
| I-01 Initialize Terraform environment | Leaseweb API credentials, selected env vars | Initialized Terraform working dir | `terraform init` completes with expected providers/modules | Run `terraform init` in `infra/terraform/leaseweb/envs/mvp` |
| I-02 Plan and apply Leaseweb substrate | Network/server variables, naming map | Provisioned and planned substrate (automated + manual contract outputs) | Plan/apply outputs include no ambiguity for remaining manual tasks | `terraform output manual_network_required` and `manual_firewall_policies` are populated and actionable |
| I-03 Generate/refresh Ansible inventory | Terraform outputs | Accurate inventory for all hosts | Inventory contains exact host/IP mapping from Terraform state/outputs | Run `scripts/bootstrap/render-ansible-inventory.sh` and compare generated inventory values with Terraform outputs |
| I-04 Apply OS and access hardening | Inventory, SSH key material | Hardened hosts, WireGuard, edge config in place | Idempotent run; no unexpected changes on second pass | Run Ansible twice; second run reports zero/expected minimal changes |
| I-05 Bootstrap Kubernetes prerequisites | Hardened Kubernetes nodes and bastion path | Nodes ready for RKE2 bootstrap playbook | Bastion can reach all kube nodes via private IP and SSH key auth | `ansible -m ping` succeeds for all kube hosts |
| I-06 Handoff to GitOps bootstrap | Cluster kubeconfig, repo access | Clear transition from infra layer to platform layer | Platform team can bootstrap Argo CD without infra rework | Argo bootstrap starts with no networking blockers |

## 5. Security and Least-Privilege Rules for Infra Changes
- No direct SSH from the internet to Kubernetes nodes.
- All infra changes go through code review except explicit break-glass incidents.
- Leaseweb API credentials are scoped to required resources only.
- Terraform state must be stored in a protected backend with encryption and access logs.
- Any manual portal action must be captured in a follow-up IaC issue if not yet codified.

## 6. Drift and Change Control
- Terraform drift check cadence: daily in CI for `mvp`, weekly for other environments.
- Ansible convergence check cadence: weekly, plus after every VM/image update.
- Emergency manual fixes must be reconciled back to code within one business day.

## 7. Definition of Done for Infra Management
- Every provisioned infrastructure resource is either:
  - declared in Terraform/Ansible, or
  - listed as approved one-time manual prerequisite.
- Naming and tagging conventions are applied consistently.
- Infrastructure can be recreated for `mvp` from documented inputs without hidden steps.
