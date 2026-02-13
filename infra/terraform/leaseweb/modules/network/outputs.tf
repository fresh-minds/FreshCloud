output "host_plan" {
  description = "Host plan keyed by hostname."
  value       = var.hosts
}

output "public_ip_map_resolved" {
  description = "Hostnames with resolved public IPs where symbolic mapping is provided."
  value       = local.public_ip_map_resolved
}

output "manual_required" {
  description = "Manual networking tasks that remain outside Terraform coverage."
  value       = var.manual_required
}
