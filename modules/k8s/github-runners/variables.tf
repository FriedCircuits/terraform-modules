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
  }))
  default = []
}

variable "controller_resources" {
  description = "Resources for the controller."
  type        = any
  default     = {}
}

variable "runner_resources" {
  description = "Resources for the runner."
  type        = any
  default     = {}
}
