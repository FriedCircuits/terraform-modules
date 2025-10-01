output "vm_id" {
  description = "VMID assigned to the Proxmox VM."
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "Name of the VM."
  value       = proxmox_virtual_environment_vm.this.name
}

output "ipv4_addresses" {
  description = "IPv4 addresses reported by the guest agent."
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}

output "resource" {
  description = "Underlying VM resource reference."
  value       = proxmox_virtual_environment_vm.this
  sensitive   = true
}

output "iso_file_id" {
  description = "File ID of the ISO attached to the VM (downloaded or provided)."
  value       = local.iso_file_id
}
