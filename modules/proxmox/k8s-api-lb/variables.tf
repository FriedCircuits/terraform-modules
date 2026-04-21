variable "name_prefix" {
  description = "Prefix used when generating container hostnames and snippet file names."
  type        = string
}

variable "vip_address" {
  description = "Virtual IP address in CIDR notation advertised by Keepalived. Set it to match the actual network CIDR for the subnet that carries the VIP."
  type        = string
}

variable "vip_dns_name" {
  description = "DNS name that should resolve to the Kubernetes API VIP."
  type        = string
}

variable "vrrp_auth_pass" {
  description = "VRRP authentication password. Keepalived PASS authentication supports up to 8 characters."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.vrrp_auth_pass) >= 1 && length(var.vrrp_auth_pass) <= 8
    error_message = "vrrp_auth_pass must be between 1 and 8 characters for Keepalived PASS authentication."
  }
}

variable "control_plane_backends" {
  description = "Talos or Kubernetes control-plane API endpoints that HAProxy forwards to."
  type = list(object({
    name = string
    ip   = string
    port = number
  }))

  validation {
    condition     = length(var.control_plane_backends) > 0
    error_message = "Provide at least one control plane backend."
  }
}

variable "instances" {
  description = "Map of load balancer containers to create. Use 2-3 instances for HA, and set each ipv4_address to the real network CIDR for the VIP subnet."
  type = map(object({
    node_name          = string
    ipv4_address       = string
    gateway            = optional(string)
    vm_id              = optional(number)
    name               = optional(string)
    description        = optional(string)
    priority           = optional(number)
    state              = optional(string)
    bridge             = optional(string)
    vlan_id            = optional(number)
    mac_address        = optional(string)
    mtu                = optional(number)
    firewall           = optional(bool)
    rate_limit         = optional(number)
    datastore_id       = optional(string)
    disk_size_gb       = optional(number)
    cpu_cores          = optional(number)
    cpu_units          = optional(number)
    cpu_limit          = optional(number)
    memory_mb          = optional(number)
    swap_mb            = optional(number)
    tags               = optional(list(string))
    protection         = optional(bool)
    startup_order      = optional(number)
    startup_up_delay   = optional(number)
    startup_down_delay = optional(number)
    started            = optional(bool)
    start_on_boot      = optional(bool)
    unprivileged       = optional(bool)
    nesting            = optional(bool)
    keyctl             = optional(bool)
  }))

  validation {
    condition     = length(var.instances) >= 2 && length(var.instances) <= 3
    error_message = "Provide between 2 and 3 load balancer instances."
  }
}

variable "default_bridge" {
  description = "Default Proxmox bridge used by container network interfaces."
  type        = string
  default     = "vmbr0"
}

variable "default_datastore_id" {
  description = "Default datastore for container root filesystems."
  type        = string
  default     = "local-lvm"
}

variable "default_disk_size_gb" {
  description = "Default root filesystem size in gigabytes."
  type        = number
  default     = 8
}

variable "default_cpu_cores" {
  description = "Default number of CPU cores per load balancer container."
  type        = number
  default     = 2
}

variable "default_cpu_units" {
  description = "Default Proxmox CPU shares for each container."
  type        = number
  default     = 1024
}

variable "default_cpu_limit" {
  description = "Default CPU limit. Set to 0 for no hard cap."
  type        = number
  default     = 0
}

variable "default_memory_mb" {
  description = "Default dedicated memory per container in megabytes."
  type        = number
  default     = 1024
}

variable "default_swap_mb" {
  description = "Default swap allocation per container in megabytes."
  type        = number
  default     = 512
}

variable "default_tags" {
  description = "Default tags applied to all load balancer containers."
  type        = list(string)
  default     = ["k8s", "api-lb", "haproxy", "keepalived"]
}

variable "default_started" {
  description = "Whether containers should be started after creation by default."
  type        = bool
  default     = true
}

variable "default_start_on_boot" {
  description = "Whether containers should start automatically when the host boots."
  type        = bool
  default     = true
}

variable "default_unprivileged" {
  description = "Whether containers should run unprivileged by default. Privileged mode is the safer default for VRRP VIP management."
  type        = bool
  default     = false
}

variable "default_nesting" {
  description = "Whether container nesting should be enabled by default."
  type        = bool
  default     = false
}

variable "default_keyctl" {
  description = "Whether keyctl support should be enabled by default."
  type        = bool
  default     = true
}

variable "default_protection" {
  description = "Whether Proxmox protection should be enabled by default."
  type        = bool
  default     = false
}

variable "default_startup_order" {
  description = "Base startup order used when instance-specific startup order is omitted."
  type        = number
  default     = 50
}

variable "default_startup_up_delay" {
  description = "Default startup delay in seconds before the next guest starts."
  type        = number
  default     = 10
}

variable "default_startup_down_delay" {
  description = "Default shutdown delay in seconds before the next guest stops."
  type        = number
  default     = 5
}

variable "network_interface_name" {
  description = "Interface name configured inside each container and referenced by Keepalived."
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
  description = "SSH public keys installed for the root account inside each container."
  type        = list(string)
  default     = []
}

variable "root_password" {
  description = "Optional root password for each container. Prefer SSH keys when possible."
  type        = string
  default     = null
  sensitive   = true
}

variable "container_template" {
  description = "Container template reference. Provide either file_id for an existing template or url to download one per target node."
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

variable "haproxy_frontend_port" {
  description = "Frontend TCP port exposed by HAProxy for the Kubernetes API."
  type        = number
  default     = 6443
}

variable "talos_api" {
  description = "Optional Talos API listener exposed on the same VIP through HAProxy. When backends are omitted, the module reuses control_plane_backends IPs with the Talos frontend port."
  type = object({
    enabled       = optional(bool)
    frontend_port = optional(number)
    backends = optional(list(object({
      name = string
      ip   = string
      port = number
    })))
  })
  default = {}
}

variable "haproxy_balance_algorithm" {
  description = "HAProxy load-balancing algorithm for the Kubernetes API backend."
  type        = string
  default     = "roundrobin"
}

variable "haproxy_health_check_interval" {
  description = "HAProxy backend health-check interval."
  type        = string
  default     = "5s"
}

variable "haproxy_health_check_fall" {
  description = "Number of failed health checks before a backend is marked down."
  type        = number
  default     = 3
}

variable "haproxy_health_check_rise" {
  description = "Number of successful health checks before a backend is marked up."
  type        = number
  default     = 2
}

variable "vrrp_virtual_router_id" {
  description = "VRRP virtual router identifier shared by all load balancer nodes."
  type        = number
  default     = 51
}

variable "vrrp_advert_int" {
  description = "VRRP advertisement interval in seconds."
  type        = number
  default     = 1
}

variable "vrrp_priority_base" {
  description = "Base priority assigned to the first sorted instance when no explicit priority is set."
  type        = number
  default     = 120
}

variable "vrrp_priority_step" {
  description = "Priority decrement applied to each subsequent sorted instance when explicit priorities are omitted."
  type        = number
  default     = 10
}

variable "keepalived_service_name" {
  description = "Systemd service name for Keepalived."
  type        = string
  default     = "keepalived"
}

variable "haproxy_service_name" {
  description = "Systemd service name for HAProxy."
  type        = string
  default     = "haproxy"
}

variable "default_description_prefix" {
  description = "Default description prefix used when instance descriptions are not explicitly set."
  type        = string
  default     = "Kubernetes API load balancer"
}

variable "pve_connection" {
  description = "Connection info for the target Proxmox environment."
  type = object({
    api_user         = string
    api_password     = optional(string)
    api_token_id     = optional(string)
    api_token_secret = optional(string)
    endpoint         = string
    tls_insecure     = optional(bool)
  })
}
