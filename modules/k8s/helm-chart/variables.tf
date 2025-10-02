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

variable "extra_namespaces" {
  description = "Extra Kubernetes Namespaces to create."
  type        = list(string)
  default     = []
}

variable "namespace_labels" {
  description = "Labels to apply to the namespace when create_namespace is enabled."
  type        = map(string)
  default     = {}
}

variable "extra_namespace_labels" {
  description = "Labels to apply to each extra namespace, keyed by namespace name."
  type        = map(map(string))
  default     = {}
}

variable "secret_name" {
  description = "The name of the Kubernetes secret"
  type        = string
  default     = ""
}

variable "secret_data" {
  description = "The data for the Kubernetes secret"
  type        = map(string)
  default     = {}
}

variable "helm_repo" {
  description = "Helm chart repo URL."
  type        = string
}

variable "name" {
  description = "Name of chart deployment."
  type        = string
}

variable "chart" {
  description = "Name of helm chart."
  type        = string
}

variable "persistence" {
  description = "Configure persistence volume on this deployment."
  type        = any
  default     = {}
}

variable "ingress" {
  description = "Configure ingress on this deployment."
  type        = any
  default     = {}
}

variable "ingress_annotations" {
  description = "Configure ingress annotations on this deployment."
  type        = map(string)
  default     = {}
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
