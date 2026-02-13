# Leaseweb Terraform Scaffold

This directory is the Infrastructure-as-Code entrypoint for the Leaseweb substrate.

## Scope
- `modules/network`: canonical host/IP model and manual-network contract.
- `modules/compute`: Leaseweb Public Cloud instance provisioning scaffold.
- `modules/security`: DNS automation (where supported) and manual firewall contract.
- `envs/mvp|stage|prod`: environment roots.

## Provider Baseline
- Terraform provider: `leaseweb/leaseweb`.
- Leaseweb Public Cloud resources are currently marked beta by the provider docs.
- Not all networking primitives in `docs/leaseweb-provisioning.md` are provider-managed yet; unresolved parts are intentionally exposed as manual-required outputs.

## Quickstart (MVP)
```bash
export LEASEWEB_TOKEN="<api-token>"
terraform -chdir=infra/terraform/leaseweb/envs/mvp init
terraform -chdir=infra/terraform/leaseweb/envs/mvp plan \
  -var-file=terraform.tfvars
```

## State Management
Use a remote, encrypted backend before first apply. Keep local state only for throwaway testing.
