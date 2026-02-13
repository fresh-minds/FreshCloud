# MVP Environment (Leaseweb)

This environment codifies the provisioning model in `docs/leaseweb-provisioning.md`.

## Run
```bash
cp terraform.tfvars.example terraform.tfvars
export LEASEWEB_TOKEN="<api-token>"
terraform init
terraform plan
```

## Notes
- Keep `enable_instance_creation=false` until Leaseweb assumptions in the provisioning doc are validated.
- `manual_network_required` and `manual_firewall_policies` outputs are authoritative for manual day-0 steps not yet provider-managed.
