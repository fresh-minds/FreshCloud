variable "project" {
  description = "Project name tag."
  type        = string
  default     = "freshcloud"
}

variable "env" {
  description = "Environment identifier."
  type        = string
}

variable "region" {
  description = "Leaseweb region code."
  type        = string
  default     = "eu-west-3"
}

variable "private_cidr" {
  description = "Private management/east-west subnet."
  type        = string
}

variable "pod_cidr" {
  description = "Kubernetes pod CIDR."
  type        = string
  default     = "10.42.0.0/16"
}

variable "service_cidr" {
  description = "Kubernetes service CIDR."
  type        = string
  default     = "10.43.0.0/16"
}

variable "public_ip_map" {
  description = "Map symbolic public IP labels to real addresses from Leaseweb allocation."
  type        = map(string)
}

variable "domain_name" {
  description = "Managed DNS zone."
  type        = string
}

variable "ingress_record_name" {
  description = "FQDN for ingress endpoint."
  type        = string
}

variable "enable_dns_records" {
  description = "Enable Leaseweb DNS A record management."
  type        = bool
  default     = false
}

variable "enable_instance_creation" {
  description = "Enable Leaseweb Public Cloud instance creation."
  type        = bool
  default     = false
}

variable "image_id" {
  description = "Leaseweb image ID for instances."
  type        = string
  default     = "UBUNTU_22_04_64BIT"
}

variable "ssh_public_key" {
  description = "Optional SSH public key material."
  type        = string
  default     = null
  nullable    = true
}

variable "admin_cidrs" {
  description = "Admin source CIDRs allowed for bastion access."
  type        = list(string)
}

variable "wireguard_cidr" {
  description = "WireGuard tunnel subnet used for privileged infrastructure access."
  type        = string
  default     = "10.99.0.0/24"
}

variable "host_plan" {
  description = "Host definitions keyed by hostname."
  type = map(object({
    role                   = string
    private_ip             = string
    public_ip_symbol       = optional(string)
    size_profile           = string
    flavor                 = string
    root_disk_size_gb      = number
    root_disk_storage_type = string
  }))
}

variable "manual_network_required" {
  description = "Manual network tasks until provider coverage exists."
  type        = list(string)
  default     = []
}

variable "manual_firewall_policies" {
  description = "Firewall rule intent (manual execution contract)."
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
