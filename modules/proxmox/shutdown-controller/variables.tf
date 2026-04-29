variable "name" {
  description = "Hostname assigned to the shutdown controller container."
  type        = string
}

variable "node_name" {
  description = "Proxmox node that hosts the shutdown controller container."
  type        = string
}

variable "ipv4_address" {
  description = "IPv4 address for the controller container. Use `dhcp` for DHCP or provide a static address in CIDR notation."
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Optional IPv4 gateway for the controller container."
  type        = string
  default     = null
}

variable "vm_id" {
  description = "Optional static Proxmox VMID for the controller container."
  type        = number
  default     = null
}

variable "description" {
  description = "Optional description shown in the Proxmox UI."
  type        = string
  default     = null
}

variable "bridge" {
  description = "Proxmox bridge attached to the controller container."
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "Optional VLAN tag for the controller container NIC."
  type        = number
  default     = null
}

variable "mac_address" {
  description = "Optional MAC address for the controller container NIC."
  type        = string
  default     = null
}

variable "mtu" {
  description = "Optional MTU for the controller container NIC."
  type        = number
  default     = null
}

variable "firewall" {
  description = "Whether to enable the Proxmox firewall flag on the container NIC."
  type        = bool
  default     = false
}

variable "rate_limit" {
  description = "Optional egress rate limit for the controller container NIC in MiB/s."
  type        = number
  default     = null
}

variable "datastore_id" {
  description = "Datastore used for the controller container root filesystem."
  type        = string
  default     = "local-lvm"
}

variable "disk_size_gb" {
  description = "Root filesystem size in gigabytes."
  type        = number
  default     = 8
}

variable "cpu_cores" {
  description = "Number of CPU cores assigned to the controller container."
  type        = number
  default     = 2
}

variable "cpu_units" {
  description = "Proxmox CPU shares for the controller container."
  type        = number
  default     = 1024
}

variable "cpu_limit" {
  description = "CPU limit for the controller container. Set to 0 for no hard cap."
  type        = number
  default     = 0
}

variable "memory_mb" {
  description = "Dedicated memory for the controller container in megabytes."
  type        = number
  default     = 1024
}

variable "swap_mb" {
  description = "Swap allocation for the controller container in megabytes."
  type        = number
  default     = 512
}

variable "tags" {
  description = "Tags applied to the controller container."
  type        = list(string)
  default     = ["shutdown-controller", "k8s", "proxmox"]
}

variable "protection" {
  description = "Whether Proxmox protection should be enabled for the controller container."
  type        = bool
  default     = false
}

variable "startup_order" {
  description = "Proxmox startup order for the controller container."
  type        = number
  default     = 20
}

variable "startup_up_delay" {
  description = "Delay in seconds before the next guest starts after this container."
  type        = number
  default     = 10
}

variable "startup_down_delay" {
  description = "Delay in seconds before the next guest stops after this container."
  type        = number
  default     = 30
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
  description = "Whether the controller container should run unprivileged."
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
  description = "SSH public keys installed for the root account inside the controller container."
  type        = list(string)
  default     = []
}

variable "root_password" {
  description = "Optional root password for the controller container. Prefer SSH keys when possible."
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

variable "packages" {
  description = "Base OS packages installed inside the controller container."
  type        = list(string)
  default = [
    "bash",
    "ca-certificates",
    "curl",
    "jq",
    "mosquitto-clients",
    "nut-client",
    "python3",
    "openssh-client",
  ]
}

variable "nut" {
  description = "Optional NUT client target settings exposed to the controller script for battery monitoring."
  type = object({
    server_host = string
    ups_name    = string
    server_port = optional(number)
  })
  default = null
}

variable "nut_credentials" {
  description = "Optional NUT credentials exposed to the controller script for authenticated monitoring integrations."
  type = object({
    username = string
    password = string
  })
  default   = null
  sensitive = true
}

variable "mqtt" {
  description = "Optional MQTT broker settings used to publish controller status and event notifications."
  type = object({
    host                = string
    port                = optional(number)
    topic_prefix        = optional(string)
    client_id           = optional(string)
    retain_status       = optional(bool)
    discovery_prefix    = optional(string)
    enable_ha_discovery = optional(bool)
  })
  default = null
}

variable "mqtt_credentials" {
  description = "Optional MQTT credentials used when publishing controller status and event notifications."
  type = object({
    username = string
    password = string
  })
  default   = null
  sensitive = true
}

variable "kubectl_version" {
  description = "kubectl version installed in the controller container."
  type        = string
  default     = "v1.30.0"
}

variable "talosctl_version" {
  description = "talosctl version installed in the controller container."
  type        = string
  default     = "v1.11.2"
}

variable "kubeconfig_content" {
  description = "Optional kubeconfig content written to the controller container."
  type        = string
  default     = null
  sensitive   = true
}

variable "talosconfig_content" {
  description = "Optional talosconfig content written to the controller container."
  type        = string
  default     = null
  sensitive   = true
}

variable "controller_script" {
  description = "Shell script installed as the shutdown controller entrypoint."
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_controller_service" {
  description = "Whether to enable and start the shutdown-controller systemd service."
  type        = bool
  default     = false
}

variable "enable_recovery_service" {
  description = "Whether to enable the one-shot shutdown-controller recovery service that runs on container boot."
  type        = bool
  default     = true
}

variable "controller_environment" {
  description = "Additional environment variables written to the controller env file."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "ceph" {
  description = "Ceph access settings for running Ceph commands through Kubernetes."
  type = object({
    namespace        = optional(string)
    tools_deployment = optional(string)
  })
  default = {}
}

variable "talos_nodes" {
  description = "Talos node names or endpoints that the controller may shut down gracefully."
  type        = list(string)
  default     = []
}

variable "linux_shutdown_targets" {
  description = "Generic Linux nodes that the controller may shut down over SSH."
  type = list(object({
    name    = optional(string)
    host    = string
    user    = optional(string)
    port    = optional(number)
    command = optional(string)
  }))
  default = []
}

variable "proxmox_nodes" {
  description = "Proxmox nodes that the controller may shut down through the Proxmox API."
  type        = list(string)
  default     = []
}

variable "linux_shutdown_ssh" {
  description = "Optional SSH settings injected into the controller for generic Linux shutdown targets."
  type = object({
    private_key_content      = string
    known_hosts_content      = optional(string)
    user                     = optional(string)
    port                     = optional(number)
    strict_host_key_checking = optional(string)
  })
  default   = null
  sensitive = true

  validation {
    condition = var.linux_shutdown_ssh == null || contains(
      ["yes", "no", "accept-new"],
      coalesce(try(var.linux_shutdown_ssh.strict_host_key_checking, null), "accept-new")
    )
    error_message = "linux_shutdown_ssh.strict_host_key_checking must be one of yes, no, or accept-new."
  }
}

variable "pve_api" {
  description = "Optional Proxmox API credentials exposed inside the controller for shutdown operations."
  type = object({
    endpoint         = string
    api_user         = string
    api_password     = optional(string)
    api_token_id     = optional(string)
    api_token_secret = optional(string)
    tls_insecure     = optional(bool)
  })
  default   = null
  sensitive = true
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
