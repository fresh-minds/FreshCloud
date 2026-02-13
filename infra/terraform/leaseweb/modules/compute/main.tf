locals {
  instances = var.enable_instance_creation ? var.instances : {}
}

resource "leaseweb_public_cloud_instance" "this" {
  for_each = local.instances

  contract = {
    billing_frequency = var.billing_frequency
    term              = var.billing_term
    type              = var.billing_type
  }

  image = {
    id = var.image_id
  }

  reference              = each.value.reference
  region                 = var.region
  type                   = each.value.flavor
  root_disk_storage_type = each.value.root_disk_storage_type
  root_disk_size         = each.value.root_disk_size_gb
  has_private_network    = each.value.has_private_network
  ssh_key                = var.ssh_public_key
  user_data              = var.ssh_public_key == null ? try(each.value.user_data, null) : null
}

resource "terraform_data" "planned_instances" {
  input = var.instances
}
