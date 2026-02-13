locals {
  network_hosts = {
    for hostname, cfg in var.host_plan :
    hostname => {
      role             = cfg.role
      private_ip       = cfg.private_ip
      public_ip_symbol = try(cfg.public_ip_symbol, null)
      size_profile     = cfg.size_profile
    }
  }

  compute_instances = {
    for hostname, cfg in var.host_plan :
    hostname => {
      reference              = hostname
      role                   = cfg.role
      flavor                 = cfg.flavor
      root_disk_size_gb      = cfg.root_disk_size_gb
      root_disk_storage_type = cfg.root_disk_storage_type
      has_private_network    = true
    }
  }

  ingress_public_ip = lookup(var.public_ip_map, "PUB_IP_4", "REPLACE_ME_INGRESS_VIP")
}

module "network" {
  source = "../../modules/network"

  project         = var.project
  env             = var.env
  region          = var.region
  private_cidr    = var.private_cidr
  pod_cidr        = var.pod_cidr
  service_cidr    = var.service_cidr
  hosts           = local.network_hosts
  public_ip_map   = var.public_ip_map
  manual_required = var.manual_network_required
}

module "compute" {
  source = "../../modules/compute"

  region                   = var.region
  image_id                 = var.image_id
  ssh_public_key           = var.ssh_public_key
  enable_instance_creation = var.enable_instance_creation
  instances                = local.compute_instances
}

module "security" {
  source = "../../modules/security"

  enable_dns_records = var.enable_dns_records
  dns_domain_name    = var.domain_name
  a_records = {
    ingress = {
      name    = var.ingress_record_name
      ttl     = 300
      content = [local.ingress_public_ip]
    }
  }
  manual_firewall_policies = var.manual_firewall_policies
}
