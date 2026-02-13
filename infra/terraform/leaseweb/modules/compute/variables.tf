variable "region" {
  description = "Leaseweb region code."
  type        = string
}

variable "image_id" {
  description = "Leaseweb image ID (for example UBUNTU_22_04_64BIT)."
  type        = string
}

variable "ssh_public_key" {
  description = "Optional SSH public key content. When set, user_data is disabled."
  type        = string
  default     = null
  nullable    = true
}

variable "enable_instance_creation" {
  description = "Enable or disable actual instance creation. Keep false until inputs are verified."
  type        = bool
  default     = false
}

variable "billing_type" {
  description = "Contract billing type (HOURLY or MONTHLY)."
  type        = string
  default     = "HOURLY"
}

variable "billing_frequency" {
  description = "Billing frequency in months."
  type        = number
  default     = 1
}

variable "billing_term" {
  description = "Billing term in months."
  type        = number
  default     = 0
}

variable "instances" {
  description = "Instance definitions keyed by logical name."
  type = map(object({
    reference              = string
    role                   = string
    flavor                 = string
    root_disk_size_gb      = number
    root_disk_storage_type = string
    has_private_network    = bool
    user_data              = optional(string)
  }))
}
