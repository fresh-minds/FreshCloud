# Raspberry Pi K3s Scaffold

## Work Item Contract
- Inputs: Raspberry Pi 5 host prepared by phase 1 scripts and the plan in `docs/raspberry-pi-k8s-plan.md`.
- Outputs: A minimal K3s configuration scaffold and baseline Kubernetes security manifests.
- Acceptance Criteria: Config templates are ready to copy onto the Pi and manifests apply cleanly with `kubectl apply -k`.
- How to Verify: Validate YAML files and run `kubectl apply --dry-run=client -k infra/k3s/manifests`.

## Directory Layout
- `config/k3s-config.yaml.example`: single-node K3s server config template.
- `manifests/`: baseline namespaces and network policy resources.

## Usage
1. Copy `infra/k3s/config/k3s-config.yaml.example` to `/etc/rancher/k3s/config.yaml` on the Pi.
2. Adjust `tls-san` and storage paths for your environment.
3. Install K3s in the next phase.
4. Apply baseline manifests:

```bash
kubectl apply -k infra/k3s/manifests
```

## Notes
- This scaffold is intentionally minimal for phase 1.
- Do not put secrets in these files. Use SOPS in later phases.
