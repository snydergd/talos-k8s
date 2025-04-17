locals {
  settings = jsondecode(file("${path.module}/../pve.json"))
}

provider "proxmox" {
  pm_user = local.settings.user
  pm_password = local.settings.pass
  pm_api_url = local.settings.base_url
  pm_tls_insecure = true
  #pm_debug = true
  #pm_log_enable = true
}

provider "kubernetes" {
  #config_path = var.k8s_config_path
  #config_context = var.k8s_config_context
  host = module.k8s.kubeconfig_data.kubernetes_client_configuration.host
  client_certificate = base64decode(module.k8s.kubeconfig_data.kubernetes_client_configuration.client_certificate)
  client_key = base64decode(module.k8s.kubeconfig_data.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.k8s.kubeconfig_data.kubernetes_client_configuration.ca_certificate)
}

provider "helm" {
  kubernetes = {
    host = module.k8s.kubeconfig_data.kubernetes_client_configuration.host
    client_certificate = base64decode(module.k8s.kubeconfig_data.kubernetes_client_configuration.client_certificate)
    client_key = base64decode(module.k8s.kubeconfig_data.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(module.k8s.kubeconfig_data.kubernetes_client_configuration.ca_certificate)
  }
}
output "kubeconfig" {
  value = module.k8s.kubeconfig
  sensitive = true
}
module "k8s" {
  source = "./modules/k8s"
  
  cluster_name = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  nodes = var.nodes
}

module "apps" {
  depends_on = [module.k8s]
  source = "./modules/apps"
}
