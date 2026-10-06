output "node" {
  description = "Managed Talos node address."
  value       = var.node
}

output "desired_configuration_sha256" {
  description = "Hash of desired configuration, not a readback or health check of the node."
  value       = nonsensitive(sha256(var.machine_configuration))
}
