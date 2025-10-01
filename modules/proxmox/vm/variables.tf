variable "name" {
  description = "Name of the virtual machine."
  type        = string
}

variable "description" {
  description = "Optional description shown in Proxmox UI."
  type        = string
  default     = null
}

variable "node" {
  description = "Proxmox node to deploy the VM on."
  type        = string
}

variable "vm_id" {
  description = "Optional static VMID. Leave null to let Proxmox pick the next available ID."
  type        = number
  default     = null
}

variable "on_boot" {
  description = "Whether the VM should be started on node boot."
  type        = bool
  default     = true
}

variable "stop_on_destroy" {
  description = "Stop the VM before destroying it."
  type        = bool
  default     = true
}

variable "scsi_hardware" {
  description = "SCSI hardware controller type."
  type        = string
  default     = "virtio-scsi-pci"
}

variable "machine_type" {
  description = "Machine type presented to the guest."
  type        = string
  default     = "q35"
}

variable "boot_order" {
  description = "Boot order for the VM."
  type        = list(string)
  default     = ["ide2", "scsi0"]
}

variable "agent_enabled" {
  description = "Enable the Proxmox guest agent."
  type        = bool
  default     = true
}

variable "vm_specs" {
  description = "CPU, memory, disk sizing, and optional BIOS type for the VM."
  type = object({
    cpu_cores    = number
    cpu_sockets  = number
    cpu_type     = string
    memory_mb    = number
    disk_size_gb = number
    bios_type    = optional(string)
  })
}

variable "disk_storage" {
  description = "Datastore used for the VM disk."
  type        = string
}

variable "disk_interface" {
  description = "Disk interface identifier."
  type        = string
  default     = "scsi0"
}

variable "disk_discard" {
  description = "Discard mode for the VM disk."
  type        = string
  default     = "on"
}

variable "disk_ssd" {
  description = "Whether to flag the disk as SSD."
  type        = bool
  default     = true
}

variable "additional_disks" {
  description = "Optional list of additional disks to attach to the VM."
  type = list(object({
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
  }))
  default = []
}

variable "iso_file_id" {
  description = "Existing file ID of the ISO to attach. Provide this when skipping the built-in download logic."
  type        = string
  default     = null
}

variable "iso_download" {
  description = "Optional configuration to download an ISO before attaching it to the VM."
  type = object({
    datastore_id       = string
    url                = string
    file_name          = string
    content_type       = optional(string)
    overwrite          = optional(bool)
    checksum           = optional(string)
    checksum_algorithm = optional(string)
  })
  default = null
}

variable "cloud_init" {
  description = "Optional cloud-init/NoCloud payloads to attach to the VM."
  type = object({
    datastore_id      = string
    disk_datastore_id = optional(string)
    interface         = optional(string)
    user_data         = optional(string)
    user_data_name    = optional(string)
    meta_data         = optional(string)
    meta_data_name    = optional(string)
    vendor_data       = optional(string)
    vendor_data_name  = optional(string)
  })
  default = null
}

variable "iso_interface" {
  description = "Interface slot for the ISO/CD-ROM."
  type        = string
  default     = "ide2"
}

variable "network" {
  description = "Network configuration for the VM."
  type = object({
    bridge      = string
    vlan_id     = optional(number)
    mac_address = optional(string)
    model       = optional(string)
  })
}

variable "os_type" {
  description = "Guest operating system type."
  type        = string
  default     = "l26"
}

variable "enable_rng" {
  description = "Whether to expose a RNG device to the VM."
  type        = bool
  default     = false
}

variable "rng_source" {
  description = "Source device for the RNG, if enabled."
  type        = string
  default     = "/dev/urandom"
}

variable "tags" {
  description = "Optional list of tags to apply to the VM."
  type        = list(string)
  default     = []
}

variable "usb_devices" {
  description = "Optional USB devices to map through to the VM."
  type = list(object({
    host    = optional(string)
    mapping = optional(string)
    usb3    = optional(bool)
  }))
  default = []

  validation {
    condition = alltrue([
      for device in var.usb_devices : try(device.host != null || device.mapping != null, false)
    ])
    error_message = "Each USB device definition must specify either host or mapping."
  }
}
