terraform {
  required_version = ">= 1.3.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.63.0"
    }
  }
}

provider "proxmox" {
  endpoint = trimspace(var.pve_connection.endpoint)
  insecure = try(var.pve_connection.tls_insecure, true)

  username = var.pve_connection.api_user
  password = try(var.pve_connection.api_password, null)
  api_token = (
    try(var.pve_connection.api_token_id, null) != null &&
    try(var.pve_connection.api_token_secret, null) != null
  ) ? format("%s=%s", var.pve_connection.api_token_id, var.pve_connection.api_token_secret) : null
  otp = try(var.pve_connection.otp, null)

  ssh {
    username    = try(var.pve_connection.ssh_user, "root")
    private_key = file(try(var.pve_connection.ssh_private_key_path, "~/.ssh/id_rsa"))
  }
}
