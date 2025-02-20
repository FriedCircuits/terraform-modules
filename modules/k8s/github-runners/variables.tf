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

variable "github_extra_helm_values" {
  description = "Additional helm values to pass to the github runner chart."
  type        = map(string)
  default     = null
}

variable "github_token" {
  description = "Github token with repo access."
  type        = string
}

variable "repos" {
  description = "List of repos to run runers for."
  type = list(object({
    repo = string
    min  = number
    max  = number
  }))
  default = []
}

variable "enable_service_account" {
  description = "Enable creation of service account for github runner."
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Name of kuberbets service account for Github runner pod."
  type        = string
  default     = "actions-runner"
}

variable "role_permissions" {
  description = "Set cluster role permissions for runners."
  type = object({
    api_groups = list(string)
    resources  = list(string)
    verbs      = list(string)
  })
  default = {
    api_groups = ["", "apps", "networking.k8s.io", "extensions"]
    resources  = ["deployments", "services", "configmaps", "secrets", "ingresses", "namespaces"]
    verbs      = ["get", "watch", "list", "patch", "update", "delete"]
  }
}
