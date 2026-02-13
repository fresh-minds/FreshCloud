# Bootstrap Scripts

These scripts automate MVP cluster bootstrap for FreshCloud on Leaseweb.

## Files
- `bootstrap.env.example`: input variables template
- `bootstrap-rke2.sh`: runs Ansible for OS prep + RKE2 HA install
- `configure-kubectl.sh`: downloads kubeconfig from primary node
- `label-and-taint-nodes.sh`: applies baseline node labels and taint policy
- `install-addons.sh`: installs MetalLB, ingress-nginx, Longhorn
- `bootstrap-argocd.sh`: installs Argo CD and optional root app
- `cluster-health.sh`: performs reproducible post-bootstrap validation
- `bootstrap-all.sh`: orchestrates complete end-to-end bootstrap

## Quick Start
```bash
cp /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env.example \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env

cp /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/ansible/inventory/hosts.ini.example \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/ansible/inventory/hosts.ini

/Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap-all.sh \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/bootstrap.env \
  /Users/karelgoense/Documents/werk/InterneFMProjecten/FreshCloud/scripts/bootstrap/ansible/inventory/hosts.ini
```
