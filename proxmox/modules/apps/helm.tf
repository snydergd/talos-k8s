
resource "kubernetes_manifest" "ip_pool" {
  for_each = { for x in provider::kubernetes::manifest_decode_multi(file("${path.module}/../../../cilium/red-pool.yaml")): "${lower(x.kind)}-${x.metadata.name}" => x }
  manifest = each.value
}
resource "kubernetes_manifest" "bgp_config" {
  for_each = { for x in provider::kubernetes::manifest_decode_multi(file("${path.module}/../../../cilium/bgp/clusterConfig.yaml")): "${lower(x.kind)}-${x.metadata.name}" => x }
  manifest = each.value
}

resource "kubernetes_namespace" "openebs_namespace" {
  metadata {
    name = "openebs"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "openebs" {
  name       = "openebs"
  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  namespace  = "openebs"

  values = [file("${path.module}/../../../openebs/values.yaml")]
}
