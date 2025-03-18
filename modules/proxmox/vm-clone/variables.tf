variable "pve_connection" {
  description = "Connection info for PVE host."
  type = object({
    node        = string
    host        = string
    ssh_user    = string
    private_key = string
  })
}

variable "clone" {
  description = "Name of template to create VM from."
  type        = string
}

variable "vm" {
  description = "Name of VM to deploy."
  type = object({
    name        = string
    description = string
  })
}

variable "cloud_init" {
  description = "Contents to pass to cloud-init."
  type        = string
  default     = ""
}

variable "full_clone" {
  description = "If true will fully copy disk to new VM from clone vs copy on write."
  type        = bool
  default     = true
}

variable "agent_enabled" {
  description = "If true will enable QEMU agent."
  type        = number
  default     = 1
}

variable "boot" {
  description = "Boot order."
  type        = string
  default     = "order=virtio0;scsi0;net0"
}

variable "specs" {
  description = "CPU, Mem settings per VM."
  type = object({
    cores   = number
    sockets = number
    memory  = number
    bios    = string
  })
  default = {
    cores   = 1
    sockets = 1
    memory  = 2048
    bios    = "seabios"
  }
}

variable "disks" {
  description = "Add extra disk to create and attach to the VM. Should be ordered by slot to keep idempotence."
  type = list(object({
    storage    = string
    type       = string
    format     = optional(string)
    size       = optional(string)
    slot       = string
    emulatessd = optional(bool)
    discard    = optional(bool)
    iothread   = optional(bool)
  }))
  default = []
}

variable "usb" {
  description = "Add extra usb device to create and attach to the VM."
  type = list(object({
    id         = string
    device_id  = optional(string)
    mapping_id = optional(string)
    port_id    = optional(string)
    usb3       = optional(bool)
  }))
  default = []
}

variable "tags" {
  description = "Comma delimited strings to pass as tags to the vm. Note not visable in the UI."
  type        = string
  default     = null
}

variable "onboot" {
  description = "Whether to have the VM startup after the PVE node starts."
  type        = bool
  default     = true
}

variable "vm_state" {
  description = "The desired state of the VM after creatation."
  type        = string
  default     = "running"
}
