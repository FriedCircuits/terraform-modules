resource "proxmox_download_file" "container_template" {
  for_each = local.template_download_enabled ? local.target_nodes : toset([])

  content_type       = "vztmpl"
  datastore_id       = coalesce(try(var.container_template.datastore_id, null), "local")
  node_name          = each.value
  url                = var.container_template.url
  checksum           = try(var.container_template.checksum, null)
  checksum_algorithm = try(var.container_template.checksum_algorithm, null)
  overwrite          = coalesce(try(var.container_template.overwrite, null), true)
}

resource "proxmox_virtual_environment_file" "hook_script" {
  for_each = local.instances

  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = each.value.node_name
  file_mode    = "0700"

  source_raw {
    data      = local.hook_scripts[each.key]
    file_name = format("%s-hook.sh", each.value.sanitized_name)
  }
}

resource "proxmox_virtual_environment_container" "this" {
  for_each = local.instances

  node_name     = each.value.node_name
  vm_id         = each.value.vm_id
  description   = each.value.description
  started       = each.value.started
  start_on_boot = each.value.start_on_boot
  protection    = each.value.protection
  unprivileged  = each.value.unprivileged
  tags          = each.value.tags

  hook_script_file_id = proxmox_virtual_environment_file.hook_script[each.key].id

  cpu {
    cores = each.value.cpu_cores
    units = each.value.cpu_units
    limit = each.value.cpu_limit
  }

  memory {
    dedicated = each.value.memory_mb
    swap      = each.value.swap_mb
  }

  disk {
    datastore_id = each.value.datastore_id
    size         = each.value.disk_size_gb
  }

  features {
    nesting = each.value.nesting
    keyctl  = each.value.keyctl
  }

  initialization {
    hostname = each.value.name

    dynamic "dns" {
      for_each = var.dns != null ? [var.dns] : []
      content {
        domain  = try(dns.value.domain, null)
        servers = try(dns.value.servers, null)
      }
    }

    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = each.value.gateway
      }
    }

    user_account {
      keys     = var.root_public_keys
      password = var.root_password
    }
  }

  network_interface {
    name        = var.network_interface_name
    bridge      = each.value.bridge
    vlan_id     = each.value.vlan_id
    mac_address = each.value.mac_address
    mtu         = each.value.mtu
    firewall    = each.value.firewall
    rate_limit  = each.value.rate_limit
  }

  operating_system {
    template_file_id = local.template_file_ids[each.key]
    type             = coalesce(try(var.container_template.type, null), "ubuntu")
  }

  startup {
    order      = tostring(each.value.startup_order)
    up_delay   = tostring(each.value.startup_up_delay)
    down_delay = tostring(each.value.startup_down_delay)
  }

  wait_for_ip {
    ipv4 = true
  }
}
