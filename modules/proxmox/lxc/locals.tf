locals {
  description = coalesce(
    var.description,
    format("LXC %s", var.name)
  )

  template_download_enabled = try(var.container_template.file_id, null) == null
  template_file_id          = local.template_download_enabled ? proxmox_download_file.container_template[0].id : var.container_template.file_id

  hook_script_file_name = coalesce(
    var.hook_script_file_name,
    format("%s-hook.sh", replace(var.name, ".", "-"))
  )

  hook_script_file_id = var.hook_script_content != null ? proxmox_virtual_environment_file.hook_script[0].id : null
}
