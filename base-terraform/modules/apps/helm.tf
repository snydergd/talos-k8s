
resource "kubernetes_manifest" "ip_pool" {
  for_each = { for x in provider::kubernetes::manifest_decode_multi(file("${path.module}/../../../cilium/red-pool.yaml")): "${lower(x.kind)}-${x.metadata.name}" => x }
  manifest = each.value
}
resource "kubernetes_manifest" "bgp_config" {
  for_each = { for x in provider::kubernetes::manifest_decode_multi(file("${path.module}/../../../cilium/bgp/clusterConfig.yaml")): "${lower(x.kind)}-${x.metadata.name}" => x }
  manifest = each.value
}
resource "kubernetes_manifest" "bgp_config_ipv6" {
  for_each = { for x in provider::kubernetes::manifest_decode_multi(file("${path.module}/../../../cilium/bgp/clusterConfig-ipv6.yaml")): "${lower(x.kind)}-${x.metadata.name}" => x }
  manifest = each.value
}

#resource "kubernetes_namespace" "openebs_namespace" {
#  metadata {
#    name = "openebs"
#    labels = {
#      "pod-security.kubernetes.io/enforce" = "privileged"
#    }
#  }
#}

#resource "helm_release" "openebs" {
#  name       = "openebs"
#  repository = "https://openebs.github.io/openebs"
#  chart      = "openebs"
#  create_namespace = true
#  namespace  = "openebs"
#  version    = "4.2.0"
#  force_update = true
#  replace = true
#
#  values = [file("${path.module}/../../../openebs/values.yaml")]
#}
