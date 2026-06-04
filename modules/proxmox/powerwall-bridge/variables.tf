variable "name" {
  description = "Hostname assigned to the Powerwall bridge container."
  type        = string
}

variable "node_name" {
  description = "Proxmox node that hosts the Powerwall bridge container."
  type        = string
}

variable "ipv4_address" {
  description = "IPv4 address for the bridge container. Use `dhcp` for DHCP or provide a static address in CIDR notation."
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Optional IPv4 gateway for the bridge container."
  type        = string
  default     = null
}

variable "vm_id" {
  description = "Optional static Proxmox VMID for the bridge container."
  type        = number
  default     = null
}

variable "description" {
  description = "Optional description shown in the Proxmox UI."
  type        = string
  default     = null
}

variable "bridge" {
  description = "Proxmox bridge attached to the bridge container NIC."
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "Optional VLAN tag for the bridge container NIC."
  type        = number
  default     = null
}

variable "mac_address" {
  description = "Optional MAC address for the bridge container NIC."
  type        = string
  default     = null
}

variable "mtu" {
  description = "Optional MTU for the bridge container NIC."
  type        = number
  default     = null
}

variable "firewall" {
  description = "Whether to enable the Proxmox firewall flag on the container NIC."
  type        = bool
  default     = false
}

variable "rate_limit" {
  description = "Optional egress rate limit for the bridge container NIC in MiB/s."
  type        = number
  default     = null
}

variable "datastore_id" {
  description = "Datastore used for the bridge container root filesystem."
  type        = string
  default     = "local-lvm"
}

variable "disk_size_gb" {
  description = "Root filesystem size in gigabytes."
  type        = number
  default     = 8
}

variable "cpu_cores" {
  description = "Number of CPU cores assigned to the bridge container."
  type        = number
  default     = 2
}

variable "cpu_units" {
  description = "Proxmox CPU shares for the bridge container."
  type        = number
  default     = 1024
}

variable "cpu_limit" {
  description = "CPU limit for the bridge container. Set to 0 for no hard cap."
  type        = number
  default     = 0
}

variable "memory_mb" {
  description = "Dedicated memory for the bridge container in megabytes."
  type        = number
  default     = 1024
}

variable "swap_mb" {
  description = "Swap allocation for the bridge container in megabytes."
  type        = number
  default     = 512
}

variable "tags" {
  description = "Tags applied to the bridge container."
  type        = list(string)
  default     = ["powerwall", "bridge", "mqtt", "home-assistant", "proxmox"]
}

variable "protection" {
  description = "Whether Proxmox protection should be enabled for the bridge container."
  type        = bool
  default     = false
}

variable "startup_order" {
  description = "Proxmox startup order for the bridge container."
  type        = number
  default     = 25
}

variable "startup_up_delay" {
  description = "Delay in seconds before the next guest starts after this container."
  type        = number
  default     = 10
}

variable "startup_down_delay" {
  description = "Delay in seconds before the next guest stops after this container."
  type        = number
  default     = 10
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
  description = "Whether the bridge container should run unprivileged."
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
  description = "SSH public keys installed for the root account inside the bridge container."
  type        = list(string)
  default     = []
}

variable "root_password" {
  description = "Optional root password for the bridge container. Prefer SSH keys when possible."
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
  description = "Base OS packages installed inside the bridge container."
  type        = list(string)
  default = [
    "bash",
    "ca-certificates",
    "curl",
    "git",
    "iproute2",
    "python3",
    "python3-pip",
    "python3-venv",
  ]
}

variable "timezone" {
  description = "Timezone used by pyPowerwall and the MQTT publisher."
  type        = string
  default     = "UTC"

  validation {
    condition     = trimspace(var.timezone) != ""
    error_message = "timezone must not be empty."
  }
}

variable "pypowerwall_repo_ref" {
  description = "Git ref used when bootstrapping the upstream pyPowerwall repository inside the container."
  type        = string
  default     = "2edc813d503bacfb1fd5033ea0499bb238530bf3"
}

variable "powerwall" {
  description = "Connectivity and credential settings passed into pyPowerwall. For Powerwall 3 string metrics, set gw_password and use host 192.168.91.1 for Wi-Fi TEDAPI or the vendor-subnet IP for v1r LAN mode."
  type = object({
    host            = optional(string)
    gw_password     = optional(string)
    password        = optional(string)
    email           = optional(string)
    wifi_host       = optional(string)
    rsa_key_content = optional(string)
  })
  default   = {}
  sensitive = true

  validation {
    condition = (
      try(var.powerwall.rsa_key_content, null) == null || try(var.powerwall.gw_password, null) != null
    )
    error_message = "powerwall.gw_password must be set when powerwall.rsa_key_content is provided."
  }

  validation {
    condition = (
      try(var.powerwall.host, null) != null ||
      try(var.powerwall.email, null) != null ||
      try(var.powerwall.wifi_host, null) != null ||
      try(var.powerwall.gw_password, null) != null ||
      try(var.powerwall.password, null) != null ||
      try(var.powerwall.rsa_key_content, null) != null
    )
    error_message = "powerwall must define enough connection information for pyPowerwall, such as host, email, gw_password, password, wifi_host, or rsa_key_content."
  }

  validation {
    condition = alltrue([
      for value in [
        try(var.powerwall.host, null),
        try(var.powerwall.gw_password, null),
        try(var.powerwall.password, null),
        try(var.powerwall.email, null),
        try(var.powerwall.wifi_host, null),
        try(var.powerwall.rsa_key_content, null),
      ] : value == null ? true : trimspace(value) != ""
    ])
    error_message = "powerwall fields must be null or non-empty strings."
  }
}

variable "route_to_powerwall" {
  description = "Optional persistent route added inside the container for TEDAPI access. In the normal design this should point to the pve3 host IP as the next hop from inside the LXC. The destination defaults to 192.168.91.1/32 and the interface defaults to the container NIC, so gateway is usually the only input you need."
  type = object({
    gateway     = string
    destination = optional(string)
    interface   = optional(string)
    onlink      = optional(bool)
  })
  default = null

  validation {
    condition = (
      var.route_to_powerwall == null ||
      (!strcontains(var.route_to_powerwall.gateway, "/") && trimspace(var.route_to_powerwall.gateway) != "")
    )
    error_message = "route_to_powerwall.gateway must be a non-empty IP address without CIDR notation."
  }
}

variable "proxy_bind_address" {
  description = "Bind address for the pyPowerwall proxy HTTP server."
  type        = string
  default     = "0.0.0.0"
}

variable "proxy_port" {
  description = "Port exposed by the pyPowerwall proxy."
  type        = number
  default     = 8675

  validation {
    condition     = var.proxy_port > 0 && var.proxy_port < 65536
    error_message = "proxy_port must be a valid TCP port."
  }
}

variable "proxy_https_mode" {
  description = "pyPowerwall proxy HTTPS mode: no, http, or yes."
  type        = string
  default     = "no"

  validation {
    condition     = contains(["no", "http", "yes"], var.proxy_https_mode)
    error_message = "proxy_https_mode must be one of: no, http, yes."
  }
}

variable "proxy_cache_expire" {
  description = "pyPowerwall cache expiration in seconds."
  type        = number
  default     = 5

  validation {
    condition     = var.proxy_cache_expire > 0
    error_message = "proxy_cache_expire must be greater than 0."
  }
}

variable "proxy_cache_ttl" {
  description = "Maximum age in seconds for degraded cached responses before the proxy returns null."
  type        = number
  default     = 30

  validation {
    condition     = var.proxy_cache_ttl > 0
    error_message = "proxy_cache_ttl must be greater than 0."
  }
}

variable "proxy_timeout" {
  description = "Timeout in seconds for pyPowerwall network calls."
  type        = number
  default     = 5

  validation {
    condition     = var.proxy_timeout > 0
    error_message = "proxy_timeout must be greater than 0."
  }
}

variable "proxy_pool_maxsize" {
  description = "Maximum concurrent upstream connections used by pyPowerwall."
  type        = number
  default     = 15

  validation {
    condition     = var.proxy_pool_maxsize > 0
    error_message = "proxy_pool_maxsize must be greater than 0."
  }
}

variable "proxy_fail_fast" {
  description = "Whether the proxy should fail fast when the connection is degraded."
  type        = bool
  default     = false
}

variable "proxy_graceful_degradation" {
  description = "Whether the proxy should serve recent cached data during transient failures."
  type        = bool
  default     = true
}

variable "proxy_health_check" {
  description = "Whether the proxy should track connection health."
  type        = bool
  default     = true
}

variable "proxy_suppress_network_errors" {
  description = "Whether to suppress individual network error lines in the proxy logs."
  type        = bool
  default     = true
}

variable "proxy_network_error_rate_limit" {
  description = "Maximum network error messages per minute per proxy function when suppression is disabled."
  type        = number
  default     = 5

  validation {
    condition     = var.proxy_network_error_rate_limit >= 0
    error_message = "proxy_network_error_rate_limit must be 0 or greater."
  }
}

variable "enable_proxy_service" {
  description = "Whether to enable and start the pyPowerwall proxy service."
  type        = bool
  default     = true
}

variable "enable_mqtt_publisher" {
  description = "Whether to enable the MQTT publisher service when mqtt is configured."
  type        = bool
  default     = true
}

variable "mqtt_publish_interval_seconds" {
  description = "Publish interval in seconds for MQTT snapshots."
  type        = number
  default     = 30

  validation {
    condition     = var.mqtt_publish_interval_seconds > 0
    error_message = "mqtt_publish_interval_seconds must be greater than 0."
  }
}

variable "mqtt_status_log_interval_seconds" {
  description = "Heartbeat interval in seconds for unchanged MQTT publisher status logs. Set to 0 to log only on status changes and errors."
  type        = number
  default     = 900

  validation {
    condition     = var.mqtt_status_log_interval_seconds >= 0
    error_message = "mqtt_status_log_interval_seconds must be 0 or greater."
  }
}

variable "mqtt_failures_before_offline" {
  description = "Number of consecutive failed publisher cycles before the MQTT bridge marks itself offline."
  type        = number
  default     = 5

  validation {
    condition     = var.mqtt_failures_before_offline > 0
    error_message = "mqtt_failures_before_offline must be greater than 0."
  }
}

variable "mqtt_fetch_timeout_seconds" {
  description = "Timeout in seconds for each HTTP request from the MQTT publisher to the local pyPowerwall proxy."
  type        = number
  default     = 15

  validation {
    condition     = var.mqtt_fetch_timeout_seconds > 0
    error_message = "mqtt_fetch_timeout_seconds must be greater than 0."
  }
}

variable "mqtt_fetch_retries" {
  description = "Number of retry attempts per endpoint fetch before the MQTT publisher gives up for that cycle."
  type        = number
  default     = 2

  validation {
    condition     = var.mqtt_fetch_retries >= 0
    error_message = "mqtt_fetch_retries must be 0 or greater."
  }
}

variable "mqtt_fetch_retry_delay_seconds" {
  description = "Delay in seconds between MQTT publisher fetch retries."
  type        = number
  default     = 1.5

  validation {
    condition     = var.mqtt_fetch_retry_delay_seconds >= 0
    error_message = "mqtt_fetch_retry_delay_seconds must be 0 or greater."
  }
}

variable "mqtt" {
  description = "Optional MQTT broker settings used for Home Assistant auto-discovery and state publishing."
  type = object({
    host             = string
    port             = optional(number)
    topic_prefix     = optional(string)
    discovery_prefix = optional(string)
    client_id        = optional(string)
    retain           = optional(bool)
  })
  default = null

  validation {
    condition = (
      var.mqtt == null || (
        trimspace(var.mqtt.host) != "" &&
        coalesce(try(var.mqtt.port, null), 1883) > 0 &&
        coalesce(try(var.mqtt.port, null), 1883) < 65536 &&
        (try(var.mqtt.topic_prefix, null) == null || trimspace(var.mqtt.topic_prefix) != "") &&
        (try(var.mqtt.discovery_prefix, null) == null || trimspace(var.mqtt.discovery_prefix) != "")
      )
    )
    error_message = "mqtt.host must be non-empty, mqtt.port must be a valid TCP port, and mqtt.topic_prefix and mqtt.discovery_prefix cannot be empty strings when provided."
  }
}

variable "mqtt_credentials" {
  description = "Optional MQTT authentication settings."
  type = object({
    username = string
    password = string
  })
  default   = null
  sensitive = true

  validation {
    condition = (
      var.mqtt_credentials == null || (
        trimspace(var.mqtt_credentials.username) != "" &&
        trimspace(var.mqtt_credentials.password) != ""
      )
    )
    error_message = "mqtt_credentials.username and mqtt_credentials.password must be non-empty when mqtt_credentials is provided."
  }
}

variable "pve_connection" {
  description = "Connection info for the target Proxmox environment used by Terraform itself."
  type = object({
    api_user         = string
    api_password     = optional(string, null)
    api_token_id     = optional(string, null)
    api_token_secret = optional(string, null)
    endpoint         = string
    tls_insecure     = optional(bool, false)
  })

  validation {
    condition = (
      trimspace(var.pve_connection.endpoint) != "" &&
      trimspace(var.pve_connection.api_user) != ""
    )
    error_message = "pve_connection.endpoint and pve_connection.api_user must be non-empty."
  }

  validation {
    condition = (
      (
        var.pve_connection.api_password != null &&
        var.pve_connection.api_token_id == null &&
        var.pve_connection.api_token_secret == null
        ) || (
        var.pve_connection.api_password == null &&
        var.pve_connection.api_token_id != null &&
        var.pve_connection.api_token_secret != null
      )
    )
    error_message = "pve_connection must use exactly one authentication method: either api_password, or api_token_id plus api_token_secret."
  }
}
