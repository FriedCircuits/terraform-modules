output "vip_address" {
  description = "Virtual IP address in CIDR notation served by Keepalived."
  value       = var.vip_address
}

output "vip_ip" {
  description = "Virtual IP address without CIDR mask."
  value       = local.vip_address_only
}

output "vip_dns_name" {
  description = "DNS name intended to resolve to the Kubernetes API VIP."
  value       = var.vip_dns_name
}

output "container_vm_ids" {
  description = "Proxmox VMIDs assigned to the load balancer containers, keyed by instance name."
  value       = { for key, ct in proxmox_virtual_environment_container.this : key => ct.vm_id }
}

output "container_names" {
  description = "Container hostnames keyed by instance name."
  value       = { for key, inst in local.instances : key => inst.name }
}

output "container_ipv4_addresses" {
  description = "Configured IPv4 addresses for the load balancer containers, keyed by instance name."
  value       = { for key, inst in local.instances : key => inst.ipv4_address }
}

output "container_ipv4_reported" {
  description = "IPv4 addresses reported by Proxmox for each container network interface."
  value       = { for key, ct in proxmox_virtual_environment_container.this : key => ct.ipv4 }
}
