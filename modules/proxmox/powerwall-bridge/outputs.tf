output "container_vm_id" {
  description = "Proxmox VMID assigned to the Powerwall bridge container."
  value       = module.lxc.container_vm_id
}

output "container_name" {
  description = "Hostname assigned to the Powerwall bridge container."
  value       = module.lxc.container_name
}

output "container_ipv4_address" {
  description = "Configured IPv4 address for the Powerwall bridge container."
  value       = module.lxc.container_ipv4_address
}

output "container_ipv4_reported" {
  description = "IPv4 addresses reported by Proxmox for the Powerwall bridge container."
  value       = module.lxc.container_ipv4_reported
}

output "proxy_port" {
  description = "TCP port exposed by the pyPowerwall proxy."
  value       = var.proxy_port
}

output "mqtt_topic_prefix" {
  description = "MQTT topic prefix used by the Home Assistant bridge publisher."
  value       = local.mqtt_topic_prefix
}

output "hook_script_file_id" {
  description = "Proxmox snippet file ID for the bootstrap hook script."
  value       = module.lxc.hook_script_file_id
  sensitive   = true
}
