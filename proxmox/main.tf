
locals {
  settings = jsondecode(file("${path.module}/../pve.json"))
}

terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc8"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0"
    }
  }
}

provider "proxmox" {
  pm_user = local.settings.user
  pm_password = local.settings.pass
  pm_api_url = local.settings.base_url
  pm_tls_insecure = true
  pm_debug = true
  pm_log_enable = true
}

provider "talos" {}

