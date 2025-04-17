locals {
  bootstrap = jsondecode(file("${path.module}/../../../bootstrap.json"))
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cluster_endpoint}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cluster_endpoint}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for x in var.nodes : "talos-${x.type}${x.index}" if x.type == "control"]
}

data "dns_a_record_set" "control_plane_ips" {
  for_each = { for x in var.nodes: "talos-${x.type}${x.index}" => x if x.type == "control" }
  host = each.key
}
data "dns_a_record_set" "worker_ips" {
  for_each = { for x in var.nodes: "talos-${x.type}${x.index}" => x if x.type == "worker" }
  host = each.key
}
#data "talos_cluster_health" "cluster_health" {
#  client_configuration = data.talos_client_configuration.this.client_configuration
#  endpoints = flatten([
#    for r in data.dns_a_record_set.control_plane_ips :
#    [
#      for ip in r.addrs : ip
#      if !strcontains(ip, ":")
#    ]
#  ])
#
#  control_plane_nodes = flatten([
#    for r in data.dns_a_record_set.control_plane_ips :
#    [
#      for ip in r.addrs : ip
#      if !strcontains(ip, ":")
#    ]
#  ])
#  worker_nodes = flatten([
#    for r in data.dns_a_record_set.worker_ips :
#    [
#      for ip in r.addrs : ip
#      if !strcontains(ip, ":")
#    ]
#  ])
#
#}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [proxmox_vm_qemu.nodes]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each                    = {for x in var.nodes : "talos-${x.type}${x.index}" => x if x.type == "control"}
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/files/ipv6-cidr.yaml.tmpl", {
      httpuser = local.bootstrap.httpuser
      httppassword = urlencode(local.bootstrap.httppassword)
    })
#    templatefile("${path.module}/templates/install-disk-and-hostname.yaml.tmpl", {
#      hostname     = each.value.hostname == null ? format("%s-cp-%s", var.cluster_name, index(keys(var.node_data.controlplanes), each.key)) : each.value.hostname
#      install_disk = each.value.install_disk
#    }),
#    file("${path.module}/files/cp-scheduling.yaml"),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [proxmox_vm_qemu.nodes]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = {for x in var.nodes : "talos-${x.type}${x.index}" => x if x.type == "worker"}
  #for_each                    = var.node_data.workers
  node                        = each.key
  config_patches = [
    templatefile("${path.module}/files/ipv6-cidr.yaml.tmpl", {
      httpuser = local.bootstrap.httpuser
      httppassword = urlencode(local.bootstrap.httppassword)
    }),
    file("${path.module}/files/kubelet-hostpath-mount.yaml")
#    templatefile("${path.module}/templates/install-disk-and-hostname.yaml.tmpl", {
#      hostname     = each.value.hostname == null ? format("%s-worker-%s", var.cluster_name, index(keys(var.node_data.workers), each.key)) : each.value.hostname
#      install_disk = each.value.install_disk
#    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.cluster_endpoint
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.cluster_endpoint
}

#resource "local_file" "kubeconfig" {
#  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
#  filename = var.k8s_config_path
#}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}
output "kubeconfig_data" {
  value     = talos_cluster_kubeconfig.this
  sensitive = true
}
