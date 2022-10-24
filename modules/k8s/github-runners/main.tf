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

module "cert_manager" {
  source = "git::git@github.com:friedcircuits/terraform-modules.git//modules/k8s/helm-chart?ref=v0.0.15"

  helm_repo        = "https://charts.jetstack.io/"
  name             = "cert-manager"
  chart            = "cert-manager"
  namespace        = var.namespace
  create_namespace = false
  chart_version    = var.cert_chart_verison

  helm_values = {
    installCRDs = true
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
  }

  depends_on = [
    kubernetes_namespace.namespace,
  ]
}

module "github" {
  source = "git::git@github.com:friedcircuits/terraform-modules.git//modules/k8s/helm-chart?ref=v0.0.15"

  helm_repo        = "https://actions-runner-controller.github.io/actions-runner-controller"
  name             = "actions-runner-controller"
  chart            = "actions-runner-controller"
  namespace        = var.namespace
  create_namespace = false
  chart_version    = var.github_chart_version


  helm_values = {
    authSecret = {
      create = false
      name   = "github-token"
    }
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
  }

  depends_on = [
    kubernetes_namespace.namespace,
    module.cert_manager
  ]
}

resource "kubernetes_manifest" "runner" {
  for_each = { for repo in var.repos : repo.repo => repo }
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"
    metadata = {
      name      = "runner-deployment"
      namespace = var.namespace
    }
    spec = {
      template = {
        spec = {
          repository = each.value.repo
        }
      }
    }
  }
}

resource "kubernetes_manifest" "runner_autoscaler" {
  for_each = { for repo in var.repos : repo.repo => repo }
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"
    metadata = {
      name      = "runner-deployment-autoscaler"
      namespace = var.namespace
    }
    spec = {
      scaleTargetRef = {
        name = "runner-deployment"
      }
      minReplicas = each.value.min
      maxReplicas = each.value.max
      metrics = [{
        type = "TotalNumberOfQueuedAndInProgressWorkflowRuns"
        repositoryNames = [
          each.value.repo
        ]
      }]
    }
  }
}
