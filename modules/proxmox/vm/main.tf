locals {
  iso_download_enabled = var.iso_download != null
  iso_download_config = local.iso_download_enabled ? merge({
    content_type       = "iso"
    overwrite          = true
    checksum           = null
    checksum_algorithm = null
  }, { for key, value in var.iso_download : key => value if value != null }) : null
  iso_file_id = var.iso_file_id != null ? var.iso_file_id : (local.iso_download_enabled ? proxmox_virtual_environment_download_file.iso[0].id : null)

  sanitized_name = replace(var.name, ".", "-")
}

resource "proxmox_virtual_environment_download_file" "iso" {
  count = local.iso_download_enabled ? 1 : 0

  node_name          = var.node
  datastore_id       = local.iso_download_config.datastore_id
  content_type       = local.iso_download_config.content_type
  url                = local.iso_download_config.url
  file_name          = local.iso_download_config.file_name
  overwrite          = local.iso_download_config.overwrite
  checksum           = local.iso_download_config.checksum
  checksum_algorithm = local.iso_download_config.checksum_algorithm
}

resource "proxmox_virtual_environment_file" "cloud_init_user" {
  count = var.cloud_init != null && try(var.cloud_init.user_data, null) != null ? 1 : 0

  node_name    = var.node
  datastore_id = var.cloud_init.datastore_id
  content_type = "snippets"
  overwrite    = true

  source_raw {
    file_name = coalesce(try(var.cloud_init.user_data_name, null), format("%s-user-data.yaml", local.sanitized_name))
    data      = var.cloud_init.user_data
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_meta" {
  count = var.cloud_init != null ? 1 : 0

  node_name    = var.node
  datastore_id = var.cloud_init.datastore_id
  content_type = "snippets"
  overwrite    = true

  source_raw {
    file_name = coalesce(try(var.cloud_init.meta_data_name, null), format("%s-meta-data.yaml", local.sanitized_name))
    data = coalesce(try(var.cloud_init.meta_data, null), yamlencode({
      "instance-id"    = local.sanitized_name
      "local-hostname" = local.sanitized_name
    }))
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_vendor" {
  count = var.cloud_init != null && try(var.cloud_init.vendor_data, null) != null ? 1 : 0

  node_name    = var.node
  datastore_id = var.cloud_init.datastore_id
  content_type = "snippets"
  overwrite    = true

  source_raw {
    file_name = coalesce(try(var.cloud_init.vendor_data_name, null), format("%s-vendor-data.yaml", local.sanitized_name))
    data      = var.cloud_init.vendor_data
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  node_name   = var.node
  vm_id       = var.vm_id

  on_boot         = var.on_boot
  stop_on_destroy = var.stop_on_destroy
  scsi_hardware   = var.scsi_hardware
  machine         = var.machine_type
  boot_order      = var.boot_order
  bios            = try(var.vm_specs.bios_type, null)

  agent {
    enabled = var.agent_enabled
  }

  cpu {
    cores   = var.vm_specs.cpu_cores
    sockets = var.vm_specs.cpu_sockets
    type    = var.vm_specs.cpu_type
  }

  memory {
    dedicated = var.vm_specs.memory_mb
    floating  = var.vm_specs.memory_mb
  }

  disk {
    datastore_id = var.disk_storage
    interface    = var.disk_interface
    size         = var.vm_specs.disk_size_gb
    discard      = var.disk_discard
    ssd          = var.disk_ssd
  }

  dynamic "disk" {
    for_each = var.additional_disks
    content {
      datastore_id = disk.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size_gb
      discard      = coalesce(try(disk.value.discard, null), var.disk_discard)
      ssd          = coalesce(try(disk.value.ssd, null), var.disk_ssd)
      cache        = try(disk.value.cache, null)
      backup       = try(disk.value.backup, null)
      aio          = try(disk.value.aio, null)
      iothread     = try(disk.value.iothread, null)
      replicate    = try(disk.value.replicate, null)
      serial       = try(disk.value.serial, null)
    }
  }

  dynamic "cdrom" {
    for_each = local.iso_file_id == null ? [] : [local.iso_file_id]
    content {
      interface = var.iso_interface
      file_id   = cdrom.value
    }
  }

  dynamic "initialization" {
    for_each = var.cloud_init != null ? [1] : []
    content {
      datastore_id        = coalesce(try(var.cloud_init.disk_datastore_id, null), var.disk_storage)
      interface           = coalesce(try(var.cloud_init.interface, null), "ide3")
      user_data_file_id   = try(proxmox_virtual_environment_file.cloud_init_user[0].id, null)
      meta_data_file_id   = try(proxmox_virtual_environment_file.cloud_init_meta[0].id, null)
      vendor_data_file_id = try(proxmox_virtual_environment_file.cloud_init_vendor[0].id, null)
    }
  }

  network_device {
    bridge      = var.network.bridge
    model       = try(var.network.model, "virtio")
    vlan_id     = try(var.network.vlan_id, null)
    mac_address = try(var.network.mac_address, null)
  }

  operating_system {
    type = var.os_type
  }

  dynamic "rng" {
    for_each = var.enable_rng ? [1] : []
    content {
      source = var.rng_source
    }
  }

  dynamic "usb" {
    for_each = var.usb_devices
    content {
      host    = try(usb.value.host, null)
      mapping = try(usb.value.mapping, null)
      usb3    = try(usb.value.usb3, null)
    }
  }

  tags = var.tags
}
