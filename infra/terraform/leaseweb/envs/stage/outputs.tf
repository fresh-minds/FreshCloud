output "host_plan" {
  description = "Host plan with roles and addressing."
  value       = module.network.host_plan
}

output "public_ip_map_resolved" {
  description = "Resolved public IP map by host for hosts exposing symbolic public IP labels."
  value       = module.network.public_ip_map_resolved
}

output "manual_network_required" {
  description = "Manual network provisioning prerequisites for Leaseweb."
  value       = module.network.manual_required
}

output "manual_firewall_policies" {
  description = "Firewall rule intent for manual implementation until provider coverage is available."
  value       = module.security.manual_firewall_policies
}

output "dns_records" {
  description = "Applied DNS records when enabled."
  value       = module.security.dns_records
}

output "compute_instance_ids" {
  description = "Public Cloud instance IDs keyed by hostname when creation is enabled."
  value       = module.compute.instance_ids
}

output "compute_instance_public_ips" {
  description = "Public Cloud instance IPs keyed by hostname when creation is enabled."
  value       = module.compute.instance_public_ips
}
