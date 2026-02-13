locals {
  dns_enabled = var.enable_dns_records && var.dns_domain_name != null
}

resource "leaseweb_dns_resource_record_set" "a" {
  for_each = local.dns_enabled ? var.a_records : {}

  domain_name = var.dns_domain_name
  name        = each.value.name
  type        = "A"
  ttl         = each.value.ttl
  content     = each.value.content
}

resource "terraform_data" "manual_firewall" {
  input = var.manual_firewall_policies
}
