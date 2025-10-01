variable "instances" {
  description = "Map of Talos control plane VMs to create."
  type = map(object({
    name                 = optional(string)
    description          = optional(string)
    proxmox_node         = string
    vm_id                = optional(number)
    iso_url              = string
    iso_storage          = optional(string)
    disk_storage         = optional(string)
    disk_interface       = optional(string)
    skip_iso_download    = optional(bool)
    existing_iso_file_id = optional(string)
    vm_specs = optional(object({
      cpu_cores    = number
      cpu_sockets  = number
      cpu_type     = string
      memory_mb    = number
      disk_size_gb = number
      bios_type    = optional(string)
    }))
    proxmox_network = optional(object({
      bridge      = string
      vlan_id     = optional(number)
      mac_address = optional(string)
      model       = optional(string)
    }))
    tags       = optional(list(string))
    enable_rng = optional(bool)
    additional_disks = optional(list(object({
      datastore_id = string
      interface    = string
      size_gb      = number
      discard      = optional(string)
      ssd          = optional(bool)
      cache        = optional(string)
      backup       = optional(bool)
      aio          = optional(string)
      iothread     = optional(bool)
      replicate    = optional(bool)
      serial       = optional(string)
    })))
    usb_devices = optional(list(object({
      host    = optional(string)
      mapping = optional(string)
      usb3    = optional(bool)
    })))
    cloud_init = optional(object({
      datastore_id      = optional(string)
      disk_datastore_id = optional(string)
      interface         = optional(string)
      user_data         = optional(string)
      user_data_name    = optional(string)
      meta_data         = optional(string)
      meta_data_name    = optional(string)
      vendor_data       = optional(string)
      vendor_data_name  = optional(string)
    }))
  }))
  validation {
    condition     = length(var.instances) > 0
    error_message = "Provide at least one control plane VM definition in instances."
  }
  validation {
    condition = alltrue([
      for inst in var.instances : !(coalesce(try(inst.skip_iso_download, null), var.default_skip_iso_download, false) && coalesce(try(inst.existing_iso_file_id, null), var.default_existing_iso_file_id, null) == null)
    ])
    error_message = "When skip_iso_download is true you must provide an existing ISO file ID either per instance or via the module default."
  }
}

variable "default_skip_iso_download" {
  description = "Whether instances should skip downloading the ISO when they do not specify otherwise."
  type        = bool
  default     = false
}

variable "default_existing_iso_file_id" {
  description = "Existing ISO file ID reused when skipping downloads and no per-instance override is supplied."
  type        = string
  default     = null
}

variable "default_vm_specs" {
  description = "Default CPU, memory, disk sizing, and optional BIOS type for control plane VMs."
  type = object({
    cpu_cores    = number
    cpu_sockets  = number
    cpu_type     = string
    memory_mb    = number
    disk_size_gb = number
    bios_type    = optional(string)
  })
  default = {
    cpu_cores    = 4
    cpu_sockets  = 1
    cpu_type     = "host"
    memory_mb    = 4096
    disk_size_gb = 50
  }
}

variable "default_disk_storage" {
  description = "Default datastore used for VM disks."
  type        = string
  default     = "local-lvm"
}

variable "default_disk_interface" {
  description = "Default disk interface identifier passed to the VM (e.g. scsi0, virtio0)."
  type        = string
  default     = "scsi0"
}

variable "default_iso_storage" {
  description = "Default datastore used for the Talos ISO. Must allow `iso` content."
  type        = string
  default     = "local"
}

variable "default_proxmox_network" {
  description = "Default Proxmox virtual NIC settings."
  type = object({
    bridge      = string
    vlan_id     = optional(number)
    mac_address = optional(string)
    model       = optional(string)
  })
  default = {
    bridge = "vmbr0"
  }
}

variable "default_tags" {
  description = "Default list of tags applied to control plane VMs."
  type        = list(string)
  default     = []
}

variable "default_enable_rng" {
  description = "Whether to expose a RNG device to control plane VMs by default."
  type        = bool
  default     = false
}

variable "default_description_prefix" {
  description = "Default prefix used when generating VM descriptions."
  type        = string
  default     = "Talos control plane"
}

variable "pve_connection" {
  description = "Connection info for the target Proxmox environment."
  type = object({
    node                 = string
    api_user             = string
    api_password         = optional(string)
    api_token_id         = optional(string)
    api_token_secret     = optional(string)
    endpoint             = string
    tls_insecure         = optional(bool)
    otp                  = optional(string)
    ssh_user             = optional(string, "root")
    ssh_private_key_path = optional(string, "~/.ssh/id_rsa")
  })

  validation {
    condition     = trimspace(var.pve_connection.endpoint) != ""
    error_message = "pve_connection.endpoint must be a non-empty URL."
  }
}
