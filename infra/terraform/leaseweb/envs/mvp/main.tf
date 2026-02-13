locals {
  host_plan = {
    "fc-mvp-euw1-k8s-01" = {
      role                   = "k8s"
      private_ip             = "10.40.0.10"
      size_profile           = "8vcpu-32gb"
      flavor                 = "lsw.m5a.2xlarge"
      root_disk_size_gb      = 100
      root_disk_storage_type = "CENTRAL"
    }
    "fc-mvp-euw1-k8s-02" = {
      role                   = "k8s"
      private_ip             = "10.40.0.11"
      size_profile           = "8vcpu-32gb"
      flavor                 = "lsw.m5a.2xlarge"
      root_disk_size_gb      = 100
      root_disk_storage_type = "CENTRAL"
    }
    "fc-mvp-euw1-k8s-03" = {
      role                   = "k8s"
      private_ip             = "10.40.0.12"
      size_profile           = "8vcpu-32gb"
      flavor                 = "lsw.m5a.2xlarge"
      root_disk_size_gb      = 100
      root_disk_storage_type = "CENTRAL"
    }
    "fc-mvp-euw1-edge-01" = {
      role                   = "edge"
      private_ip             = "10.40.0.20"
      public_ip_symbol       = "PUB_IP_2"
      size_profile           = "2vcpu-4gb"
      flavor                 = "lsw.m3.large"
      root_disk_size_gb      = 40
      root_disk_storage_type = "CENTRAL"
    }
    "fc-mvp-euw1-edge-02" = {
      role                   = "edge"
      private_ip             = "10.40.0.21"
      public_ip_symbol       = "PUB_IP_3"
      size_profile           = "2vcpu-4gb"
      flavor                 = "lsw.m3.large"
      root_disk_size_gb      = 40
      root_disk_storage_type = "CENTRAL"
    }
    "fc-mvp-euw1-access-01" = {
      role                   = "access"
      private_ip             = "10.40.0.30"
      public_ip_symbol       = "PUB_IP_1"
      size_profile           = "2vcpu-4gb"
      flavor                 = "lsw.m3.large"
      root_disk_size_gb      = 40
      root_disk_storage_type = "CENTRAL"
    }
  }

  network_hosts = {
    for hostname, cfg in local.host_plan :
    hostname => {
      role             = cfg.role
      private_ip       = cfg.private_ip
      public_ip_symbol = try(cfg.public_ip_symbol, null)
      size_profile     = cfg.size_profile
    }
  }

  compute_instances = {
    for hostname, cfg in local.host_plan :
    hostname => {
      reference              = hostname
      role                   = cfg.role
      flavor                 = cfg.flavor
      root_disk_size_gb      = cfg.root_disk_size_gb
      root_disk_storage_type = cfg.root_disk_storage_type
      has_private_network    = true
    }
  }

  manual_network_required = [
    "Create and attach private VLAN fc-mvp-euw1-pri-vlan with CIDR 10.40.0.0/24.",
    "Reserve routed public /29 and map it to PUB_IP_1..PUB_IP_4 in terraform.tfvars.",
    "Ensure k8s nodes are not directly reachable from the public internet.",
    "Configure failover VIP PUB_IP_4 across edge nodes (Keepalived)."
  ]

  manual_firewall_policies = {
    edge_public = {
      description = "Internet-to-ingress boundary."
      inbound_rules = [
        {
          description = "HTTP from internet"
          protocol    = "tcp"
          port        = "80"
          sources     = ["0.0.0.0/0"]
        },
        {
          description = "HTTPS from internet"
          protocol    = "tcp"
          port        = "443"
          sources     = ["0.0.0.0/0"]
        }
      ]
    }
    access_public = {
      description = "Restricted bastion and WireGuard entrypoint."
      inbound_rules = [
        {
          description = "SSH from approved admin CIDRs"
          protocol    = "tcp"
          port        = "22"
          sources     = var.admin_cidrs
        },
        {
          description = "WireGuard from approved admin CIDRs"
          protocol    = "udp"
          port        = "51820"
          sources     = var.admin_cidrs
        }
      ]
    }
    private_admin = {
      description = "Private admin access from WireGuard subnet."
      inbound_rules = [
        {
          description = "SSH from WireGuard"
          protocol    = "tcp"
          port        = "22"
          sources     = [var.wireguard_cidr]
        },
        {
          description = "Kubernetes API from WireGuard"
          protocol    = "tcp"
          port        = "6443"
          sources     = [var.wireguard_cidr]
        }
      ]
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
  manual_required = local.manual_network_required
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
  manual_firewall_policies = local.manual_firewall_policies
}
