output "ip_address_default" {
  description = "VM IP Addpress via default address."
  value       = proxmox_vm_qemu.vm.default_ipv4_address
}

output "ssh_host" {
  description = "VM IP Addpress via SSH Host"
  value       = proxmox_vm_qemu.vm.ssh_host
}
