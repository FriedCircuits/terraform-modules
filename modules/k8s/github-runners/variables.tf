variable "namespace" {
  description = "Which Kubernetes Namespace to deploy the chart into."
  type        = string
  default     = "github"
}

variable "cert_chart_verison" {
  description = "Helm chart version for cert manager. Required for github runners."
  type        = string
  default     = "v1.10.0"
}

variable "github_chart_version" {
  description = "The version of the helm chart to use. Note that this is different from the app/container version."
  type        = string
  default     = "0.21.0"
}

variable "github_controller_extra_helm_values" {
  description = "Additional helm values to pass to the github runner chart."
  type        = any
  default     = null
}

variable "github_runner_extra_helm_values" {
  description = "Additional helm values to pass to the github runner chart."
  type        = any
  default     = null
}

variable "service_account_name" {
  description = "Service account name for the runner."
  type        = string
  default     = null
}

variable "create_service_account" {
  description = "Create a service account for the runner. Otherwise if `service_account_name` is set, it will assume it is already created."
  type        = bool
  default     = true
}

variable "github_runner_storage" {
  description = "Storage configuration for the runner."
  type = object({
    access_modes = list(string)
    class_name   = string
    size         = string
  })
}
variable "storage_class_name" {
  description = "Storage class name for the runner."
  type        = string
  default     = null
}

variable "cluster_role_rules" {
  description = "List of rules for the Kubernetes ClusterRole"
  type = list(object({
    api_groups = list(string)
    resources  = list(string)
    verbs      = list(string)
  }))
  default = [
    {
      api_groups = ["*"]
      resources  = ["*"]
      verbs      = ["*"]
    },
    {
      api_groups = [""]
      resources  = ["*"]
      verbs      = ["*"]
    }
  ]
}

variable "fs_group" {
  description = "FS group for the runner."
  type        = number
  default     = 1000
}

variable "github_token" {
  description = "Github token with repo access."
  type        = string
}

variable "repos" {
  description = "List of repos to run runners for."
  type = list(object({
    repo = string
    min  = number
    max  = number

    # A second scale set for the same repository, distinguished by name. The
    # scale set name is what a workflow puts in runs-on, so a repository that
    # needs runners on more than one architecture needs more than one name.
    #
    # Empty by default, which reproduces exactly the name a single scale set
    # has always had.
    name_suffix = optional(string, "")

    # Overrides the module-wide nodeSelector for this scale set only. The point
    # of the suffix above: an arm64 entry beside an amd64 one, both for the same
    # repository.
    node_selector = optional(map(string))
  }))
  default = []
}

variable "controller_resources" {
  description = "Resources for the controller."
  type        = any
  default     = {}
}

variable "runner_resources" {
  description = "Resources for the runner agent container."
  type        = any
  default     = {}
}

variable "image_pull_secrets" {
  description = <<-EOT
    Image pull secrets for the pod a job runs in. The container hook builds
    that pod from this template, so a secret on the runner's service account
    does not reach it. They must already exist in the namespace, and anything
    that expires needs refreshing elsewhere.
  EOT
  type        = list(string)
  default     = []
}

variable "workflow_image_pull_policy" {
  description = <<-EOT
    imagePullPolicy for the container a job runs in.

    In kubernetes container mode every job gets a fresh pod, so a job whose
    workflow names a container image pays a registry pull unless the node
    already holds that image. On a small cluster with a large CI image that
    pull is most of the job: four minutes of pull for thirty seconds of work
    is an ordinary result.

    `IfNotPresent` makes the node's copy count. It is only safe where the
    image is referenced immutably -- a digest, or a tag that is never moved --
    because a node holding an older copy of a moving tag will keep using it.

    Null leaves Kubernetes' own default, which is `Always` for `:latest` and
    `IfNotPresent` for everything else.
  EOT
  type        = string
  default     = null

  validation {
    condition = var.workflow_image_pull_policy == null || contains(
      ["Always", "IfNotPresent", "Never"],
      var.workflow_image_pull_policy
    )
    error_message = "workflow_image_pull_policy must be Always, IfNotPresent or Never."
  }
}

variable "workflow_resources" {
  description = <<-EOT
    Resources for the container a job actually runs in.

    Separate from `runner_resources`: in kubernetes container mode each job
    gets a second pod, and that is the one that compiles, tests and runs
    browsers. The runner agent beside it only talks to the API.

    Leaving this empty makes those pods BestEffort, which is the first thing
    the kubelet kills when a node runs short -- so a heavy job is killed by
    the pressure it caused, and the scheduler, having been told to reserve
    nothing, is free to put the next one on the same node.
  EOT
  type        = any
  default     = {}
}
