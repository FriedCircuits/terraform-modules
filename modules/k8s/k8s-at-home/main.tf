resource "kubernetes_namespace" "namespace" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

locals {
  values = yamlencode(
    merge(tomap({
      env = merge({
        TZ = var.timezone,
      }, var.helm_envs)
    }),
    var.helm_values,
  ))
}

resource "helm_release" "k8s" {
  repository = "https://k8s-at-home.com/charts/"
  name       = var.name
  chart      = var.chart
  version    = var.chart_version
  namespace  = var.namespace

  values = [
    local.values,
  ]

  depends_on = [
    kubernetes_namespace.namespace,
  ]
}
