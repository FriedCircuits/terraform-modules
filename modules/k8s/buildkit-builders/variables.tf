variable "namespace" {
  description = <<-EOT
    Namespace for the builders. Rootless BuildKit needs unconfined seccomp and
    AppArmor to nest containers, so this namespace has to permit them -- a
    PodSecurity level of `privileged`, or an equivalent exemption.
  EOT
  type        = string
}

variable "builders" {
  description = <<-EOT
    The builders to create, keyed by buildx builder name. The StatefulSet is
    that key plus "0", which is buildx's own convention -- builder `shared-arm64`
    is StatefulSet `shared-arm640`.

    Naming matters more than it looks: the state PVC is derived from the
    StatefulSet name, so keeping a name identical is what lets an existing cache
    be reused. Renaming a builder starts it cold.

    Leave it null for one builder per entry in `architectures`, which is the
    common case.
  EOT
  type = map(object({
    node_selector = optional(map(string))
    storage_size  = optional(string)
    labels        = optional(map(string))
    limits        = optional(map(string))
  }))
  default = null
}

variable "architectures" {
  description = <<-EOT
    Shorthand for the common case: one builder per architecture, named
    `<name_prefix>-<arch>`, pinned to nodes of that arch. Ignored when
    `builders` is set.

    A build targeting a platform has to run on a node of that platform unless
    you want it emulated, which is slow enough to defeat the point.
  EOT
  type        = list(string)
  default     = ["amd64", "arm64"]
}

variable "name_prefix" {
  description = "Builder names are `<prefix>-<arch>`. buildx addresses the StatefulSet as `<name>0`."
  type        = string
  default     = "shared"
}

variable "image" {
  description = "Rootless BuildKit image. Must be a `-rootless` tag; the module does not grant privileged."
  type        = string
  default     = "moby/buildkit:v0.32.2-rootless"
}

variable "state_storage" {
  description = <<-EOT
    Size of the per-builder PVC holding BuildKit state. This is the point of the
    module: the layer cache lives here and survives between runs and across
    repositories, instead of every job booting a builder and starting cold.
  EOT
  type        = string
  default     = "100Gi"
}

variable "storage_class_name" {
  description = "Storage class for the state volume. Block storage; this is a single writer."
  type        = string
  default     = null
}

variable "fs_group" {
  description = <<-EOT
    Group that owns the state volume.

    Not optional in practice. Rootless BuildKit runs as this uid/gid, a freshly
    provisioned volume mounts root-owned, and without an fsGroup the daemon
    cannot create its own lockfile:

      could not lock /home/user/.local/share/buildkit/buildkitd.lock

    It crashloops, which is exactly what happens when buildx is left to create a
    builder with a PVC itself -- it emits an empty pod securityContext. Declaring
    the builder here is what makes it start.
  EOT
  type        = number
  default     = 1000
}

variable "limits" {
  description = <<-EOT
    Optional limits for the builder pod. Empty by default and worth leaving
    empty: a build throttled mid-layer, or OOM-killed part-way through, reads as
    a flake rather than a resource problem.
  EOT
  type        = map(string)
  default     = {}
}

variable "resources" {
  description = "Requests for the builder pod."
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "250m"
    memory = "1Gi"
  }
}

variable "gc_reserved_space" {
  description = "BuildKit keeps this much cache before collecting."
  type        = string
  default     = "10GB"
}

variable "gc_max_used_space" {
  description = "Upper bound on cache on disk. Keep it under `state_storage` or the volume fills and the builder wedges."
  type        = string
  default     = "70GB"
}

variable "gc_min_free_space" {
  description = "Free space BuildKit tries to keep available on the state volume."
  type        = string
  default     = "15GB"
}

variable "labels" {
  description = "Extra labels for the builder objects."
  type        = map(string)
  default     = {}
}
