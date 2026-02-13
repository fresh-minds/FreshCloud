# Production Environment (Leaseweb)

This root reuses the same modules as MVP with production host maps and stricter inputs.

## Run
```bash
cp terraform.tfvars.example terraform.tfvars
export LEASEWEB_TOKEN="<api-token>"
terraform init
terraform plan
```

Use reviewed and approved values only. Keep `enable_instance_creation=false` until full change approval.
