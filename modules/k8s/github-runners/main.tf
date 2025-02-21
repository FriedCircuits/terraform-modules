resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "github" {
  metadata {
    name      = "github-token"
    namespace = var.namespace
  }
  data = {
    github_token = var.github_token
  }
  type = "Opaque"
}

module "github_controller" {
  source = "../helm-chart"

  helm_repo        = "oci://ghcr.io/actions/actions-runner-controller-charts"
  name             = "arc"
  chart            = "gha-runner-scale-set-controller"
  namespace        = var.namespace
  create_namespace = false
  chart_version    = var.github_chart_version

  helm_values = merge(var.github_extra_helm_values, {
    resources = {
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  })

  depends_on = [
    kubernetes_namespace.namespace
  ]
}

module "github_runner" {
  for_each = { for repo in var.repos : repo.repo => repo }
  source   = "../helm-chart"

  helm_repo        = "oci://ghcr.io/actions/actions-runner-controller-charts"
  name             = "${split("/", each.value.repo)[3]}-${split("/", each.value.repo)[4]}"
  chart            = "gha-runner-scale-set"
  namespace        = var.namespace
  create_namespace = false
  chart_version    = var.github_chart_version

  helm_values = merge(var.github_extra_helm_values, {
    githubConfigUrl    = each.value.repo
    githubConfigSecret = "github-token"
    maxRunners         = each.value.max
    minRunners         = each.value.min
    resources = {
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  })

  depends_on = [
    kubernetes_namespace.namespace,
    module.github_controller
  ]
}
