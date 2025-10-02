locals {
  instance_user_data_maps = {
    for key, inst in var.instances : key => try(yamldecode(try(inst.cloud_init.user_data, "{}")), {})
  }
  instance_user_data_decodable = {
    for key, inst in var.instances : key => can(yamldecode(try(inst.cloud_init.user_data, "")))
  }
  instance_user_data_provided = {
    for key, inst in var.instances : key => inst.cloud_init != null && try(inst.cloud_init.user_data, null) != null
  }
  instance_iso_settings = {
    for key, inst in var.instances : key => {
      skip = coalesce(try(inst.skip_iso_download, null), var.default_skip_iso_download, false)
      iso_file_id = try(
        element(
          compact([
            try(inst.existing_iso_file_id, null),
            var.default_existing_iso_file_id
          ]),
          0
        ),
        null
      )
    }
  }
}

locals {
  instances = {
    for key, inst in var.instances : key => {
      name = coalesce(try(inst.name, null), key)
      description = coalesce(
        try(inst.description, null),
        format("%s %s", var.default_description_prefix, coalesce(try(inst.name, null), key))
      )
      proxmox_node         = inst.proxmox_node
      vm_id                = try(inst.vm_id, null)
      iso_storage          = coalesce(try(inst.iso_storage, null), var.default_iso_storage)
      disk_storage         = coalesce(try(inst.disk_storage, null), var.default_disk_storage)
      disk_interface       = coalesce(try(inst.disk_interface, null), var.default_disk_interface)
      skip_iso_download    = local.instance_iso_settings[key].skip
      existing_iso_file_id = local.instance_iso_settings[key].iso_file_id
      vm_specs             = try(inst.vm_specs, null) != null ? inst.vm_specs : var.default_vm_specs
      proxmox_network      = merge(var.default_proxmox_network, try(inst.proxmox_network, {}))
      tags                 = coalesce(try(inst.tags, null), var.default_tags)
      enable_rng           = coalesce(try(inst.enable_rng, null), var.default_enable_rng)
      additional_disks     = coalesce(try(inst.additional_disks, null), [])
      usb_devices          = coalesce(try(inst.usb_devices, null), [])
      iso_download = local.instance_iso_settings[key].skip ? null : {
        datastore_id = coalesce(try(inst.iso_storage, null), var.default_iso_storage)
        url          = inst.iso_url
        file_name    = basename(inst.iso_url)
        overwrite    = true
      }
      iso_file_id = local.instance_iso_settings[key].skip ? local.instance_iso_settings[key].iso_file_id : null
      cloud_init = inst.cloud_init == null ? null : merge(
        {
          datastore_id = coalesce(
            try(inst.cloud_init.datastore_id, null),
            coalesce(try(inst.iso_storage, null), var.default_iso_storage)
          )
          disk_datastore_id = coalesce(
            try(inst.cloud_init.disk_datastore_id, null),
            coalesce(try(inst.disk_storage, null), var.default_disk_storage)
          )
        },
        {
          for k, v in inst.cloud_init : k => (
            k == "user_data" && local.instance_user_data_provided[key] && local.instance_user_data_decodable[key]
            ? yamlencode(merge(
              local.instance_user_data_maps[key],
              {
                machine = merge(
                  try(local.instance_user_data_maps[key].machine, {}),
                  {
                    network = merge(
                      try(local.instance_user_data_maps[key].machine.network, {}),
                      {
                        hostname = coalesce(
                          try(local.instance_user_data_maps[key].machine.network.hostname, null),
                          replace(replace(coalesce(try(inst.name, null), key), " ", "-"), ".", "-")
                        )
                      }
                    )
                  }
                )
              }
            ))
            : v
          )
          if !contains(["datastore_id", "disk_datastore_id"], k)
        }
      )
    }
  }
}

module "proxmox_vm" {
  for_each = local.instances
  source   = "../vm"

  name        = each.value.name
  description = each.value.description
  node        = each.value.proxmox_node
  vm_id       = each.value.vm_id

  vm_specs         = each.value.vm_specs
  disk_storage     = each.value.disk_storage
  disk_interface   = each.value.disk_interface
  iso_download     = each.value.iso_download
  iso_file_id      = each.value.iso_file_id
  network          = each.value.proxmox_network
  tags             = each.value.tags
  enable_rng       = each.value.enable_rng
  cloud_init       = each.value.cloud_init
  additional_disks = each.value.additional_disks
  usb_devices      = each.value.usb_devices
}
