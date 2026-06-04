module "powerwall_bridge" {
  source = "../.."

  name      = "powerwall-bridge"
  node_name = "pve1"
  vm_id     = 1450

  ipv4_address = "192.168.10.50/24"
  gateway      = "192.168.10.1"
  timezone     = "UTC"

  container_template = {
    file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    type    = "debian"
  }

  dns = {
    domain  = "example.internal"
    servers = ["192.168.10.1"]
  }

  root_public_keys = [file("~/.ssh/id_ed25519.pub")]

  powerwall = {
    host        = "192.168.91.1"
    gw_password = var.powerwall_gateway_password
  }

  mqtt = {
    host             = "mqtt.example.internal"
    topic_prefix     = "powerwall/powerwall-bridge"
    discovery_prefix = "homeassistant"
  }

  mqtt_credentials = {
    username = var.mqtt_username
    password = var.mqtt_password
  }

  route_to_powerwall = {
    gateway = "192.168.10.2"
  }

  pve_connection = {
    endpoint     = "https://pve.example.internal:8006"
    api_user     = "terraform@pam"
    api_password = var.proxmox_password
  }
}

variable "powerwall_gateway_password" {
  type      = string
  sensitive = true
}

variable "mqtt_username" {
  type = string
}

variable "mqtt_password" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}
