variable "pve_connection" {
  description = "Connection info for PVE host."
  type        = object({
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
  type        = object({
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

variable "specs" {
  description = "CPU, Mem settings per VM."
  type        = object({
    cores        = number
    sockets      = number
    memory       = number
    disk_size    = string
    disk_storage = string
    disk_type    = string
  })
  default = {
    cores        = 1
    sockets      = 1
    memory       = 2048
    disk_size    = "30G"
    disk_storage = "local-lvm"
    disk_type    = "virtio"
  }
}

variable "tags" {
  description = "Comma delimited strings to pass as tags to the vm. Note not visable in the UI."
  type        = string
  default     = null
}
