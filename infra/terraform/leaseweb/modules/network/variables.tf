variable "project" {
  description = "Project identifier."
  type        = string
}

variable "env" {
  description = "Environment name (mvp, stage, prod)."
  type        = string
}

variable "region" {
  description = "Leaseweb region code."
  type        = string
}

variable "private_cidr" {
  description = "Private management/east-west network CIDR."
  type        = string
}

variable "pod_cidr" {
  description = "Kubernetes pod CIDR plan."
  type        = string
}

variable "service_cidr" {
  description = "Kubernetes service CIDR plan."
  type        = string
}

variable "hosts" {
  description = "Canonical host plan keyed by hostname."
  type = map(object({
    role             = string
    private_ip       = string
    public_ip_symbol = optional(string)
    size_profile     = string
  }))
}

variable "public_ip_map" {
  description = "Map of symbolic public IP labels (for example PUB_IP_1) to real addresses."
  type        = map(string)
  default     = {}
}

variable "manual_required" {
  description = "Manual provider tasks that must be completed outside Terraform."
  type        = list(string)
  default     = []
}
