moved {
  from = proxmox_virtual_environment_container.this
  to   = module.lxc.proxmox_virtual_environment_container.this
}

moved {
  from = proxmox_virtual_environment_file.hook_script
  to   = module.lxc.proxmox_virtual_environment_file.hook_script[0]
}

module "lxc" {
  source = "../lxc"

  name                   = local.container_name
  node_name              = var.node_name
  ipv4_address           = var.ipv4_address
  gateway                = var.gateway
  vm_id                  = var.vm_id
  description            = local.description
  bridge                 = var.bridge
  vlan_id                = var.vlan_id
  mac_address            = var.mac_address
  mtu                    = var.mtu
  firewall               = var.firewall
  rate_limit             = var.rate_limit
  datastore_id           = var.datastore_id
  disk_size_gb           = var.disk_size_gb
  cpu_cores              = var.cpu_cores
  cpu_units              = var.cpu_units
  cpu_limit              = var.cpu_limit
  memory_mb              = var.memory_mb
  swap_mb                = var.swap_mb
  tags                   = var.tags
  protection             = var.protection
  startup_order          = var.startup_order
  startup_up_delay       = var.startup_up_delay
  startup_down_delay     = var.startup_down_delay
  started                = var.started
  start_on_boot          = var.start_on_boot
  unprivileged           = var.unprivileged
  nesting                = var.nesting
  keyctl                 = var.keyctl
  network_interface_name = var.network_interface_name
  dns                    = var.dns
  root_public_keys       = var.root_public_keys
  root_password          = var.root_password
  container_template     = var.container_template
  snippet_datastore_id   = var.snippet_datastore_id
  hook_script_content    = local.hook_script
  hook_script_file_name  = format("%s-hook.sh", replace(var.name, ".", "-"))
  pve_connection         = var.pve_connection
}
