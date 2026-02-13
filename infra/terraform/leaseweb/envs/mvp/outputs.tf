output "host_plan" {
  description = "MVP host plan with roles and addressing."
  value       = module.network.host_plan
}

output "public_ip_map_resolved" {
  description = "Resolved public IP map by host for hosts that expose symbolic public IP labels."
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

output "ansible_inventory_model" {
  description = "Model used by scripts/bootstrap/render-ansible-inventory.sh."
  value = {
    bastion_host = "fc-mvp-euw1-access-01"
    proxyjump    = format("ubuntu@%s", lookup(var.public_ip_map, "PUB_IP_1", "PUB_IP_1"))
    hosts = {
      for hostname, cfg in module.network.host_plan :
      hostname => {
        role       = cfg.role
        private_ip = cfg.private_ip
        ansible_host = cfg.role == "k8s" ? cfg.private_ip : (
          try(cfg.public_ip_symbol, null) == null ? cfg.private_ip : lookup(var.public_ip_map, cfg.public_ip_symbol, cfg.public_ip_symbol)
        )
      }
    }
  }
}
