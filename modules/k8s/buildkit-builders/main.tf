# Long-lived BuildKit builders, one per architecture.
#
# buildx can create a builder itself, and for a throwaway per-job builder that
# is fine. It is not fine for a persistent one: asked for a PVC it emits a
# StatefulSet with an empty pod securityContext, rootless BuildKit cannot take
# the lock on a root-owned volume, and the pod crashloops with
#
#   could not lock /home/user/.local/share/buildkit/buildkitd.lock
#
# Declaring them here fixes that at the source and makes them shared
# infrastructure rather than something each repository's workflow reinvents.
# A job attaches by name (`docker/setup-buildx-action` with `name:` and
# `cleanup: false`) and gets a warm cache instead of a cold boot.

locals {
  # Either an explicit map of builders, or the one-per-architecture shorthand.
  builders = (
    var.builders != null
    ? var.builders
    : { for arch in var.architectures : "${var.name_prefix}-${arch}" => {
      node_selector = { "kubernetes.io/arch" = arch }
    } }
  )

  common_labels = merge(
    {
      "app.kubernetes.io/name"       = "buildkit"
      "app.kubernetes.io/component"  = "builder"
      "app.kubernetes.io/managed-by" = "terraform"
    },
    var.labels,
  )
}

resource "kubernetes_config_map" "buildkitd" {
  for_each = local.builders

  metadata {
    # buildx names the StatefulSet `<builder>0`, and its config map after that.
    name      = "${each.key}0-config"
    namespace = var.namespace
    labels    = merge(local.common_labels, { "app" = "${each.key}0" })
  }

  data = {
    # Garbage collection, so a shared cache cannot grow until it fills the
    # volume and wedges every build that shares it.
    "buildkitd.toml" = <<-EOT
      [worker.oci]
        gc = true
        reservedSpace = "${var.gc_reserved_space}"
        maxUsedSpace = "${var.gc_max_used_space}"
        minFreeSpace = "${var.gc_min_free_space}"

      [history]
        maxAge = 172800
        maxEntries = 50
    EOT
  }
}

resource "kubernetes_stateful_set" "builder" {
  for_each = local.builders

  metadata {
    name      = "${each.key}0"
    namespace = var.namespace
    labels    = merge(local.common_labels, { "app" = "${each.key}0" }, try(each.value.labels, null) != null ? each.value.labels : {})
  }

  spec {
    replicas     = 1
    service_name = "${each.key}0"

    selector {
      match_labels = { "app" = "${each.key}0" }
    }

    template {
      metadata {
        labels = merge(local.common_labels, { "app" = "${each.key}0" })
      }

      spec {
        # A build runs whatever a branch tells it to, so the builder is rootless
        # and never privileged. `fs_group` is what lets that unprivileged uid
        # write the state volume -- see the variable for the failure without it.
        security_context {
          fs_group               = var.fs_group
          fs_group_change_policy = "OnRootMismatch"
          run_as_non_root        = false
        }

        node_selector = try(each.value.node_selector, null) != null ? each.value.node_selector : {}

        container {
          name  = "buildkitd"
          image = var.image

          args = [
            "--oci-worker-no-process-sandbox",
            "--config",
            "/etc/buildkit/buildkitd.toml",
          ]

          security_context {
            run_as_user                = var.fs_group
            run_as_group               = var.fs_group
            run_as_non_root            = false
            privileged                 = false
            allow_privilege_escalation = true
            read_only_root_filesystem  = false

            # Rootless BuildKit nests containers, which the default profile
            # forbids. This is why the namespace needs a PodSecurity exemption.
            seccomp_profile {
              type = "Unconfined"
            }
          }

          readiness_probe {
            exec {
              command = ["buildctl", "debug", "workers"]
            }
            initial_delay_seconds = 5
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = var.resources.cpu
              memory = var.resources.memory
            }
            limits = try(each.value.limits, null) != null ? each.value.limits : var.limits
          }

          volume_mount {
            name       = "state"
            mount_path = "/home/user/.local/share/buildkit"
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/buildkit"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.buildkitd[each.key].metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "state"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.storage_class_name

        resources {
          requests = {
            storage = try(each.value.storage_size, null) != null ? each.value.storage_size : var.state_storage
          }
        }
      }
    }
  }
}
