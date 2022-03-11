resource "kubernetes_namespace" "namespace" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_namespace" "namespaces" {
  for_each = toset(var.extra_namespaces)
  metadata {
    name = each.value
  }
}

locals {
  values = yamlencode(
    merge(var.persistence != {} ? tomap({
      persistence = merge({
         enabled = true
       },
       var.persistence)
      }) : {}, var.ingress != {} ? tomap({
      ingress = merge({
         enabled = true
       }, tomap({
       annotations = var.ingress_annotations}),
       var.ingress)
      }) : {},
      var.helm_envs,
      var.helm_values
    )
  )
}

resource "helm_release" "k8s" {
  repository = var.helm_repo
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
