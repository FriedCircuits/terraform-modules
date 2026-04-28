terraform {
  required_version = ">= 1.3.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.103.0"
    }
  }
}

provider "proxmox" {
  endpoint = trimspace(var.pve_connection.endpoint)
  insecure = try(var.pve_connection.tls_insecure, false)

  username = var.pve_connection.api_user
  password = try(var.pve_connection.api_password, null)
  api_token = (
    try(var.pve_connection.api_token_id, null) != null &&
    try(var.pve_connection.api_token_secret, null) != null
  ) ? format("%s=%s", var.pve_connection.api_token_id, var.pve_connection.api_token_secret) : null
}
