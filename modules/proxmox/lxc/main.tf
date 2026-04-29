resource "proxmox_download_file" "container_template" {
  count = local.template_download_enabled ? 1 : 0

  content_type       = "vztmpl"
  datastore_id       = coalesce(try(var.container_template.datastore_id, null), "local")
  node_name          = var.node_name
  url                = var.container_template.url
  checksum           = try(var.container_template.checksum, null)
  checksum_algorithm = try(var.container_template.checksum_algorithm, null)
  overwrite          = coalesce(try(var.container_template.overwrite, null), true)
}

resource "proxmox_virtual_environment_file" "hook_script" {
  count = var.hook_script_content != null ? 1 : 0

  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.node_name
  file_mode    = "0700"

  source_raw {
    data      = var.hook_script_content
    file_name = local.hook_script_file_name
  }
}

resource "proxmox_virtual_environment_container" "this" {
  node_name     = var.node_name
  vm_id         = var.vm_id
  description   = local.description
  started       = var.started
  start_on_boot = var.start_on_boot
  protection    = var.protection
  unprivileged  = var.unprivileged
  tags          = sort(distinct([for tag in var.tags : lower(tag)]))

  hook_script_file_id = local.hook_script_file_id

  cpu {
    cores = var.cpu_cores
    units = var.cpu_units
    limit = var.cpu_limit
  }

  memory {
    dedicated = var.memory_mb
    swap      = var.swap_mb
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size_gb
  }

  features {
    nesting = var.nesting
    keyctl  = var.keyctl
  }

  initialization {
    hostname = var.name

    dynamic "dns" {
      for_each = var.dns != null ? [var.dns] : []
      content {
        domain  = try(dns.value.domain, null)
        servers = try(dns.value.servers, null)
      }
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.gateway
      }
    }

    user_account {
      keys     = var.root_public_keys
      password = var.root_password
    }
  }

  network_interface {
    name        = var.network_interface_name
    bridge      = var.bridge
    vlan_id     = var.vlan_id
    mac_address = var.mac_address
    mtu         = var.mtu
    firewall    = var.firewall
    rate_limit  = var.rate_limit
  }

  operating_system {
    template_file_id = local.template_file_id
    type             = coalesce(try(var.container_template.type, null), "debian")
  }

  startup {
    order      = tostring(var.startup_order)
    up_delay   = tostring(var.startup_up_delay)
    down_delay = tostring(var.startup_down_delay)
  }

  wait_for_ip {
    ipv4 = true
  }
}
