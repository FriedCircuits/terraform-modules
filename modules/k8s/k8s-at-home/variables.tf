variable "chart_version" {
  description = "The version of the helm chart to use. Note that this is different from the app/container version."
  type        = string
}

variable "create_namespace" {
  description = "Create namespace or deploy to existing."
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Which Kubernetes Namespace to deploy the chart into."
  type        = string
  default     = "default"
}

variable "name" {
  description = "Name of chart deployment."
  type        = string
}

variable "chart" {
  description = "Name of k8s-at-home chart."
  type        = string
}

variable "timezone" {
  description = "Timezone for the service."
  type        = string
  default     = "US/Pacific"
}

variable "persistence" {
  description = "Configure persistence volume on this deployment."
  type        = map(string)
  default     = {}
  # Map of keys under the persistance.config value. See: https://github.com/k8s-at-home/library-charts/tree/main/charts/stable/common
# Example
# persistence = {
#   mountPath    = "/config"
#   size         = "20Gi"
#   storageClass = "nfs-client"
# }
}

variable "ingress" {
  description = "Configure ingress on this deployment."
  type        = any
  default     = {}
  # Map of keys under the ingress.main value. See: https://github.com/k8s-at-home/library-charts/tree/main/charts/stable/common
# Example
# ingress = {
#   hosts = [{
#     host = "domain.example.com"
#     paths = [{
#       path = "/"
#     }]
#   }]
# }
}

variable "ingress_annotations" {
  description = "Configure ingress annotations on this deployment."
  type        = map(string)
  default     = {}
  # Map of keys under the ingress.main.annotations value. See: https://github.com/k8s-at-home/library-charts/tree/main/charts/stable/common
}

variable "helm_envs" {
  description = "Map of envs for helm chart. Merged with timezone."
  type        = any
  default     = {}
}

variable "helm_values" {
  description = "Additional helm values to pass in as a map. Timezone will be included already."
  type        = any
  default     = {}
}
