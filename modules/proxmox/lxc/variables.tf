variable "name" {
  description = "Hostname assigned to the container."
  type        = string
}

variable "node_name" {
  description = "Proxmox node that hosts the container."
  type        = string
}

variable "ipv4_address" {
  description = "IPv4 address for the container. Use `dhcp` for DHCP or provide a static address in CIDR notation."
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Optional IPv4 gateway for the container."
  type        = string
  default     = null
}

variable "vm_id" {
  description = "Optional static Proxmox VMID for the container."
  type        = number
  default     = null
}

variable "description" {
  description = "Optional description shown in the Proxmox UI."
  type        = string
  default     = null
}

variable "bridge" {
  description = "Proxmox bridge attached to the container."
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "Optional VLAN tag for the container NIC."
  type        = number
  default     = null
}

variable "mac_address" {
  description = "Optional MAC address for the container NIC."
  type        = string
  default     = null
}

variable "mtu" {
  description = "Optional MTU for the container NIC."
  type        = number
  default     = null
}

variable "firewall" {
  description = "Whether to enable the Proxmox firewall flag on the container NIC."
  type        = bool
  default     = false
}

variable "rate_limit" {
  description = "Optional egress rate limit for the container NIC in MiB/s."
  type        = number
  default     = null
}

variable "datastore_id" {
  description = "Datastore used for the container root filesystem."
  type        = string
  default     = "local-lvm"
}

variable "disk_size_gb" {
  description = "Root filesystem size in gigabytes."
  type        = number
  default     = 8
}

variable "cpu_cores" {
  description = "Number of CPU cores assigned to the container."
  type        = number
  default     = 2
}

variable "cpu_units" {
  description = "Proxmox CPU shares for the container."
  type        = number
  default     = 1024
}

variable "cpu_limit" {
  description = "CPU limit for the container. Set to 0 for no hard cap."
  type        = number
  default     = 0
}

variable "memory_mb" {
  description = "Dedicated memory for the container in megabytes."
  type        = number
  default     = 1024
}

variable "swap_mb" {
  description = "Swap allocation for the container in megabytes."
  type        = number
  default     = 512
}

variable "tags" {
  description = "Tags applied to the container."
  type        = list(string)
  default     = []
}

variable "protection" {
  description = "Whether Proxmox protection should be enabled for the container."
  type        = bool
  default     = false
}

variable "startup_order" {
  description = "Proxmox startup order for the container."
  type        = number
  default     = 50
}

variable "startup_up_delay" {
  description = "Delay in seconds before the next guest starts after this container."
  type        = number
  default     = 10
}

variable "startup_down_delay" {
  description = "Delay in seconds before the next guest stops after this container."
  type        = number
  default     = 5
}

variable "started" {
  description = "Whether the container should be started after creation."
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Whether the container should start automatically when the host boots."
  type        = bool
  default     = true
}

variable "unprivileged" {
  description = "Whether the container should run unprivileged."
  type        = bool
  default     = false
}

variable "nesting" {
  description = "Whether container nesting should be enabled."
  type        = bool
  default     = false
}

variable "keyctl" {
  description = "Whether keyctl support should be enabled inside the container."
  type        = bool
  default     = true
}

variable "network_interface_name" {
  description = "Interface name configured inside the container."
  type        = string
  default     = "eth0"
}

variable "dns" {
  description = "Optional DNS settings applied during container initialization."
  type = object({
    domain  = optional(string)
    servers = optional(list(string))
  })
  default = null
}

variable "root_public_keys" {
  description = "SSH public keys installed for the root account inside the container."
  type        = list(string)
  default     = []
}

variable "root_password" {
  description = "Optional root password for the container. Prefer SSH keys when possible."
  type        = string
  default     = null
  sensitive   = true
}

variable "container_template" {
  description = "Container template reference. Provide either file_id for an existing template or url to download on the target node."
  type = object({
    file_id            = optional(string)
    url                = optional(string)
    datastore_id       = optional(string)
    checksum           = optional(string)
    checksum_algorithm = optional(string)
    overwrite          = optional(bool)
    type               = optional(string)
  })

  validation {
    condition = (
      try(var.container_template.file_id, null) != null && try(var.container_template.url, null) == null
      ) || (
      try(var.container_template.file_id, null) == null && try(var.container_template.url, null) != null
    )
    error_message = "container_template must define exactly one of file_id or url."
  }
}

variable "snippet_datastore_id" {
  description = "Datastore that allows snippet content for hook scripts. Usually a directory-backed storage such as local."
  type        = string
  default     = "local"
}

variable "hook_script_content" {
  description = "Optional hook script content uploaded as a Proxmox snippet and attached to the container."
  type        = string
  default     = null
  sensitive   = true
}

variable "hook_script_file_name" {
  description = "Optional snippet file name used when hook_script_content is provided. Defaults to <name>-hook.sh."
  type        = string
  default     = null
}

variable "pve_connection" {
  description = "Connection info for the target Proxmox environment used by Terraform itself."
  type = object({
    api_user         = string
    api_password     = optional(string)
    api_token_id     = optional(string)
    api_token_secret = optional(string)
    endpoint         = string
    tls_insecure     = optional(bool)
  })
}
