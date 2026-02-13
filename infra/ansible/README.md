# Ansible Scaffold (Leaseweb MVP)

This directory handles host-level automation after infrastructure provisioning.

## Structure
- `inventories/<env>/hosts.yml`: static inventory templates.
- `playbooks/`: execution entrypoints.
- `roles/`: idempotent role scaffolding.

## Run (MVP)
```bash
ansible-playbook -i infra/ansible/inventories/mvp/hosts.yml infra/ansible/playbooks/site.yml
```

## Notes
- Access model assumes bastion-first SSH and WireGuard for privileged network access.
- Fill secrets via Ansible Vault, SOPS, or external secret injection before enabling WireGuard/edge roles.
