locals {
  hosts_with_public_symbols = {
    for hostname, cfg in var.hosts :
    hostname => cfg
    if try(cfg.public_ip_symbol, null) != null
  }

  public_ip_map_resolved = {
    for hostname, cfg in local.hosts_with_public_symbols :
    hostname => lookup(var.public_ip_map, cfg.public_ip_symbol, cfg.public_ip_symbol)
  }
}

resource "terraform_data" "network_contract" {
  input = {
    project         = var.project
    env             = var.env
    region          = var.region
    private_cidr    = var.private_cidr
    pod_cidr        = var.pod_cidr
    service_cidr    = var.service_cidr
    hosts           = var.hosts
    manual_required = var.manual_required
  }
}
