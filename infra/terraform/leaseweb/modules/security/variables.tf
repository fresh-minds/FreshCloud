variable "enable_dns_records" {
  description = "Enable creation of DNS A records via Leaseweb DNS API."
  type        = bool
  default     = false
}

variable "dns_domain_name" {
  description = "Managed DNS zone domain name."
  type        = string
  default     = null
  nullable    = true
}

variable "a_records" {
  description = "DNS A records keyed by logical name."
  type = map(object({
    name    = string
    ttl     = number
    content = list(string)
  }))
  default = {}
}

variable "manual_firewall_policies" {
  description = "Firewall policy model that is currently manual-required."
  type = map(object({
    description = string
    inbound_rules = list(object({
      description = string
      protocol    = string
      port        = string
      sources     = list(string)
    }))
  }))
  default = {}
}
