module "lxc" {
  for_each = local.instances

  source = "../lxc"

  name                   = each.value.name
  node_name              = each.value.node_name
  ipv4_address           = each.value.ipv4_address
  gateway                = each.value.gateway
  vm_id                  = each.value.vm_id
  description            = each.value.description
  bridge                 = each.value.bridge
  vlan_id                = each.value.vlan_id
  mac_address            = each.value.mac_address
  mtu                    = each.value.mtu
  firewall               = each.value.firewall
  rate_limit             = each.value.rate_limit
  datastore_id           = each.value.datastore_id
  disk_size_gb           = each.value.disk_size_gb
  cpu_cores              = each.value.cpu_cores
  cpu_units              = each.value.cpu_units
  cpu_limit              = each.value.cpu_limit
  memory_mb              = each.value.memory_mb
  swap_mb                = each.value.swap_mb
  tags                   = each.value.tags
  protection             = each.value.protection
  startup_order          = each.value.startup_order
  startup_up_delay       = each.value.startup_up_delay
  startup_down_delay     = each.value.startup_down_delay
  started                = each.value.started
  start_on_boot          = each.value.start_on_boot
  unprivileged           = each.value.unprivileged
  nesting                = each.value.nesting
  keyctl                 = each.value.keyctl
  network_interface_name = var.network_interface_name
  dns                    = var.dns
  root_public_keys       = var.root_public_keys
  root_password          = var.root_password
  container_template     = var.container_template
  snippet_datastore_id   = var.snippet_datastore_id
  hook_script_content    = local.hook_scripts[each.key]
  hook_script_file_name  = format("%s-hook.sh", each.value.sanitized_name)
  pve_connection         = var.pve_connection
}
