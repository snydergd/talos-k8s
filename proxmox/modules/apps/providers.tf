
terraform {
  required_providers {
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

