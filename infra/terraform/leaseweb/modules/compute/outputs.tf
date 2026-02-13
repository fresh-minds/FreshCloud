output "planned_instances" {
  description = "Planned instances whether or not creation is enabled."
  value       = terraform_data.planned_instances.output
}

output "instance_ids" {
  description = "Created instance IDs keyed by logical name."
  value       = { for name, instance in leaseweb_public_cloud_instance.this : name => instance.id }
}

output "instance_public_ips" {
  description = "Created instance public IP lists keyed by logical name."
  value       = { for name, instance in leaseweb_public_cloud_instance.this : name => [for ip in instance.ips : ip.ip] }
}
