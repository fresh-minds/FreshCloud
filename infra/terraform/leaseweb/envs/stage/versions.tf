terraform {
  required_version = ">= 1.9.0"

  required_providers {
    leaseweb = {
      source  = "leaseweb/leaseweb"
      version = "~> 1.2.0"
    }
  }
}
