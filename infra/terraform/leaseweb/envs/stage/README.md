# Stage Environment (Leaseweb)

This root reuses the same modules as MVP with environment-specific host maps.

## Run
```bash
cp terraform.tfvars.example terraform.tfvars
export LEASEWEB_TOKEN="<api-token>"
terraform init
terraform plan
```

Keep `enable_instance_creation=false` until provisioning assumptions are validated for stage.
