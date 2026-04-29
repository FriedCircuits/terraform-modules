output "container_vm_id" {
  description = "Proxmox VMID assigned to the container."
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "container_name" {
  description = "Hostname assigned to the container."
  value       = var.name
}

output "container_ipv4_address" {
  description = "Configured IPv4 address for the container."
  value       = var.ipv4_address
}

output "container_ipv4_reported" {
  description = "IPv4 addresses reported by Proxmox for the container."
  value       = proxmox_virtual_environment_container.this.ipv4
}

output "hook_script_file_id" {
  description = "Proxmox snippet file ID for the uploaded hook script, or null when no hook script is configured."
  value       = local.hook_script_file_id
}
