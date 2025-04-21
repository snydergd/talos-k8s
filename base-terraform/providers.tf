
terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc8"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0"
    }
    dns = {
      source = "opentofu/dns"
      version = "3.4.2"
    }
    kubernetes = {
      source = "opentofu/kubernetes"
      version = "2.36.0"
    }
    helm = {
      source = "opentofu/helm"
      version = "3.0.0-pre2"
    }
  }
}

