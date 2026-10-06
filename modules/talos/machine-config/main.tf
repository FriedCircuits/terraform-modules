# Manage one node; workload health checks remain the caller's responsibility.
resource "talos_machine_configuration_apply" "this" {
  node                        = var.node
  endpoint                    = coalesce(var.endpoint, var.node)
  machine_configuration_input = var.machine_configuration
  client_configuration_wo     = var.client_configuration
  apply_mode                  = var.apply_mode

  # Terraform removal only forgets management; it must never reset a live node.
  on_destroy = {
    reset    = false
    graceful = true
    reboot   = false
  }
}
