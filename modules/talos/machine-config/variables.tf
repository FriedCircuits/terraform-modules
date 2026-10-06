variable "node" {
  description = "Address of the single Talos node whose configuration is managed."
  type        = string
  validation {
    condition     = length(trimspace(var.node)) > 0
    error_message = "node must be a nonempty address."
  }
}

variable "endpoint" {
  description = "Talos API endpoint; defaults to direct access to node."
  type        = string
  default     = null
}

variable "machine_configuration" {
  description = "Complete existing-cluster machine configuration, including any volume documents. Contains credentials: protect Terraform state and use the existing cluster secrets."
  type        = string
  sensitive   = true
  validation {
    condition     = length(trimspace(var.machine_configuration)) > 0
    error_message = "machine_configuration must contain a complete Talos configuration."
  }
}

variable "client_configuration" {
  description = "Existing authorized Talos admin client credentials (base64-encoded PEM). Passed to the provider write-only and not persisted as a module input."
  type = object({
    ca_certificate     = string
    client_certificate = string
    client_key         = string
  })
  sensitive = true
  ephemeral = true
}

variable "apply_mode" {
  description = "Talos apply mode. no_reboot fails if a reboot is required; opt into auto or reboot only during node maintenance."
  type        = string
  default     = "no_reboot"
  validation {
    condition     = contains(["no_reboot", "auto", "reboot"], var.apply_mode)
    error_message = "apply_mode must be no_reboot, auto, or reboot."
  }
}
