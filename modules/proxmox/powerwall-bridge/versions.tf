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
  insecure = var.pve_connection.tls_insecure

  username = var.pve_connection.api_user
  password = var.pve_connection.api_password
  api_token = (
    var.pve_connection.api_token_id != null &&
    var.pve_connection.api_token_secret != null
  ) ? format("%s=%s", var.pve_connection.api_token_id, var.pve_connection.api_token_secret) : null
}
