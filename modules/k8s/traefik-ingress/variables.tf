variable "namespace" {
  description = "Which Kubernetes Namespace to deploy the traefik ingress CRDs into."
  type        = string
  default     = "default"
}

variable "name" {
  description = "Name to use for Traefik ingress release. Must be unique per namespace."
  type        = string
}

variable "host" {
  description = "Traefik host match."
  type        = string
}

variable "cert_resolver" {
  description = "Name of cert resolver to use to generate TLS cert for this hostname."
  type        = string
}

variable "service" {
  description = "Kubernetes service name to route host match rule to."
  type        = string
}

variable "service_port" {
  description = "Kubernetes service port to route to."
  type        = number
}
