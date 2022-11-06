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
        },
      var.helm_envs)
      }),
      tomap({
        persistence = {
          config = merge({
            enabled = var.persistence != {} ? true : false
            },
        var.persistence) }
      }),
      tomap({
        ingress = {
          main = merge({
            enabled = var.ingress != {} ? true : false
            }, tomap({
            annotations = var.ingress_annotations }),
        var.ingress) }
      }),
      var.helm_values
    )
  )
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
