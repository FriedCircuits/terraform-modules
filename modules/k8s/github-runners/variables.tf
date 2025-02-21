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
