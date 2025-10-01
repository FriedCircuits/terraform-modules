output "vm_ids" {
  description = "VMIDs assigned to the control plane nodes, keyed by instance name."
  value       = { for key, mod in module.proxmox_vm : key => mod.vm_id }
}

output "vm_names" {
  description = "Names of the control plane VMs, keyed by instance name."
  value       = { for key, mod in module.proxmox_vm : key => mod.name }
}

output "iso_file_ids" {
  description = "File IDs of the Talos ISO attached to each VM, keyed by instance name."
  value       = { for key, mod in module.proxmox_vm : key => mod.iso_file_id }
}
