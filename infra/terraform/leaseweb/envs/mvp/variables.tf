variable "project" {
  description = "Project name tag."
  type        = string
  default     = "freshcloud"
}

variable "env" {
  description = "Environment identifier."
  type        = string
  default     = "mvp"
}

variable "region" {
  description = "Leaseweb region code."
  type        = string
  default     = "eu-west-3"
}

variable "private_cidr" {
  description = "Private management/east-west subnet."
  type        = string
  default     = "10.40.0.0/24"
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
  default = {
    PUB_IP_1 = "REPLACE_ME_BASTION_PUBLIC_IP"
    PUB_IP_2 = "REPLACE_ME_EDGE01_PUBLIC_IP"
    PUB_IP_3 = "REPLACE_ME_EDGE02_PUBLIC_IP"
    PUB_IP_4 = "REPLACE_ME_INGRESS_VIP"
  }
}

variable "domain_name" {
  description = "Managed DNS zone."
  type        = string
  default     = "example.com"
}

variable "ingress_record_name" {
  description = "FQDN for ingress endpoint."
  type        = string
  default     = "apps.example.com."
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
  default     = ["198.51.100.0/24"]
}

variable "wireguard_cidr" {
  description = "WireGuard tunnel subnet used for privileged infrastructure access."
  type        = string
  default     = "10.99.0.0/24"
}
