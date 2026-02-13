output "dns_records" {
  description = "Applied DNS A records keyed by logical name."
  value = {
    for name, record in leaseweb_dns_resource_record_set.a :
    name => {
      fqdn    = record.name
      type    = record.type
      ttl     = record.ttl
      content = record.content
    }
  }
}

output "manual_firewall_policies" {
  description = "Manual firewall policy definitions pending provider coverage."
  value       = terraform_data.manual_firewall.output
}
