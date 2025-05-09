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

  helm_values = merge(var.github_controller_extra_helm_values, {
    resources = var.controller_resources
  })

  depends_on = [
    kubernetes_namespace.namespace
  ]
}

locals {
  runner_template = {
    spec = merge(var.github_runner_extra_helm_values.template.spec, {
      securityContext = {
        fsGroup = var.fs_group
      }
      serviceAccountName = var.service_account_name
      containers = var.service_account_name != null ? [
        {
          name    = "runner"
          image   = "ghcr.io/actions/actions-runner:latest"
          command = ["/home/runner/run.sh"]
          env = [
            {
              name  = "ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER"
              value = "false"
            },
            {
              name  = "ACTIONS_RUNNER_CONTAINER_HOOK_TEMPLATE"
              value = "/home/runner/pod-templates/default.yaml"
            }
          ]
          volumeMounts = [
            {
              name      = "pod-templates"
              mountPath = "/home/runner/pod-templates"
              readOnly  = true
            }
          ]
        }
      ] : null
      volumes = var.service_account_name != {} ? [
        {
          name = "pod-templates"
          configMap = {
            name = kubernetes_config_map.gha_runner[0].metadata[0].name
          }
        }
      ] : null
    })
  }
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

  helm_values = merge(var.github_runner_extra_helm_values, {
    githubConfigUrl    = each.value.repo
    githubConfigSecret = "github-token"
    maxRunners         = each.value.max
    minRunners         = each.value.min
    template           = local.runner_template
    containerMode = {
      type = "kubernetes"
      kubernetesModeWorkVolumeClaim = {
        accessModes      = var.github_runner_storage.access_modes
        storageClassName = var.github_runner_storage.class_name
        resources = {
          requests = {
            storage = var.github_runner_storage.size
          }
        }
      }
    }
    resources = var.runner_resources
  })

  depends_on = [
    kubernetes_namespace.namespace,
    module.github_controller
  ]
}

resource "kubernetes_service_account" "gha_runner" {
  count = var.service_account_name != null && var.create_service_account ? 1 : 0
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role" "gha_runner_role" {
  count = var.service_account_name != null && var.create_service_account ? 1 : 0
  metadata {
    name = "gha-runner-role"
  }
  dynamic "rule" {
    for_each = var.cluster_role_rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

resource "kubernetes_cluster_role_binding" "gha_runner_binding" {
  count = var.service_account_name != null && var.create_service_account ? 1 : 0
  metadata {
    name = "gha-runner-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.gha_runner_role[0].metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.gha_runner[0].metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_config_map" "gha_runner" {
  count = var.service_account_name != null && var.create_service_account ? 1 : 0
  metadata {
    name      = "pod-templates"
    namespace = var.namespace
  }
  data = {
    "default.yaml" = <<EOT
---
apiVersion: v1
kind: PodTemplate
metadata:
  name: runner-pod-template
  labels:
    app: runner-pod-template
spec:
  serviceAccountName: gha-runner
  securityContext:
    fsGroup: ${var.fs_group}
EOT
  }
}
