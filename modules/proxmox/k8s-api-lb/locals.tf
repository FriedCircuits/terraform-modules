locals {
  ordered_instance_keys = sort(keys(var.instances))

  instance_defaults = {
    for index, key in local.ordered_instance_keys : key => {
      generated_name     = format("%s-%s", var.name_prefix, key)
      priority           = var.vrrp_priority_base - (index * var.vrrp_priority_step)
      state              = index == 0 ? "MASTER" : "BACKUP"
      startup_order      = var.default_startup_order + index
      startup_up_delay   = var.default_startup_up_delay
      startup_down_delay = var.default_startup_down_delay
    }
  }

  instances = {
    for key, inst in var.instances : key => {
      name               = coalesce(try(inst.name, null), local.instance_defaults[key].generated_name)
      description        = coalesce(try(inst.description, null), format("%s %s", var.default_description_prefix, coalesce(try(inst.name, null), local.instance_defaults[key].generated_name)))
      node_name          = inst.node_name
      ipv4_address       = inst.ipv4_address
      ipv4_address_only  = split("/", inst.ipv4_address)[0]
      gateway            = try(inst.gateway, null)
      vm_id              = try(inst.vm_id, null)
      priority           = coalesce(try(inst.priority, null), local.instance_defaults[key].priority)
      state              = upper(coalesce(try(inst.state, null), local.instance_defaults[key].state))
      bridge             = coalesce(try(inst.bridge, null), var.default_bridge)
      vlan_id            = try(inst.vlan_id, null)
      mac_address        = try(inst.mac_address, null)
      mtu                = try(inst.mtu, null)
      firewall           = coalesce(try(inst.firewall, null), false)
      rate_limit         = try(inst.rate_limit, null)
      datastore_id       = coalesce(try(inst.datastore_id, null), var.default_datastore_id)
      disk_size_gb       = coalesce(try(inst.disk_size_gb, null), var.default_disk_size_gb)
      cpu_cores          = coalesce(try(inst.cpu_cores, null), var.default_cpu_cores)
      cpu_units          = coalesce(try(inst.cpu_units, null), var.default_cpu_units)
      cpu_limit          = coalesce(try(inst.cpu_limit, null), var.default_cpu_limit)
      memory_mb          = coalesce(try(inst.memory_mb, null), var.default_memory_mb)
      swap_mb            = coalesce(try(inst.swap_mb, null), var.default_swap_mb)
      tags               = sort(distinct([for tag in concat(var.default_tags, coalesce(try(inst.tags, null), [])) : lower(tag)]))
      protection         = coalesce(try(inst.protection, null), var.default_protection)
      startup_order      = coalesce(try(inst.startup_order, null), local.instance_defaults[key].startup_order)
      startup_up_delay   = coalesce(try(inst.startup_up_delay, null), local.instance_defaults[key].startup_up_delay)
      startup_down_delay = coalesce(try(inst.startup_down_delay, null), local.instance_defaults[key].startup_down_delay)
      started            = coalesce(try(inst.started, null), var.default_started)
      start_on_boot      = coalesce(try(inst.start_on_boot, null), var.default_start_on_boot)
      unprivileged       = coalesce(try(inst.unprivileged, null), var.default_unprivileged)
      nesting            = coalesce(try(inst.nesting, null), var.default_nesting)
      keyctl             = coalesce(try(inst.keyctl, null), var.default_keyctl)
      sanitized_name     = replace(coalesce(try(inst.name, null), local.instance_defaults[key].generated_name), ".", "-")
    }
  }

  target_nodes = toset([for inst in values(local.instances) : inst.node_name])

  template_download_enabled = try(var.container_template.file_id, null) == null

  template_file_ids = {
    for key, inst in local.instances : key => (
      local.template_download_enabled
      ? proxmox_download_file.container_template[inst.node_name].id
      : var.container_template.file_id
    )
  }

  talos_api_enabled       = coalesce(try(var.talos_api.enabled, null), false)
  talos_api_frontend_port = coalesce(try(var.talos_api.frontend_port, null), 50000)
  talos_api_backends = local.talos_api_enabled ? (
    try(var.talos_api.backends, null) != null ? var.talos_api.backends : [
      for backend in var.control_plane_backends : {
        name = backend.name
        ip   = backend.ip
        port = local.talos_api_frontend_port
      }
    ]
  ) : []

  haproxy_configs = {
    for key, inst in local.instances : key => templatefile("${path.module}/templates/haproxy.cfg.tftpl", {
      frontend_port         = var.haproxy_frontend_port
      balance_algorithm     = var.haproxy_balance_algorithm
      health_check_interval = var.haproxy_health_check_interval
      health_check_fall     = var.haproxy_health_check_fall
      health_check_rise     = var.haproxy_health_check_rise
      backends              = var.control_plane_backends
      talos_api_enabled     = local.talos_api_enabled
      talos_frontend_port   = local.talos_api_frontend_port
      talos_backends        = local.talos_api_backends
    })
  }

  keepalived_configs = {
    for key, inst in local.instances : key => templatefile("${path.module}/templates/keepalived.conf.tftpl", {
      state             = inst.state
      interface         = var.network_interface_name
      virtual_router_id = var.vrrp_virtual_router_id
      priority          = inst.priority
      advert_int        = var.vrrp_advert_int
      auth_pass         = var.vrrp_auth_pass
      vip_address       = var.vip_address
      instance_ip       = inst.ipv4_address_only
      peers             = [for peer_key, peer in local.instances : peer.ipv4_address_only if peer_key != key]
      haproxy_service   = var.haproxy_service_name
    })
  }

  bootstrap_scripts = {
    for key, inst in local.instances : key => templatefile("${path.module}/templates/bootstrap.sh.tftpl", {
      haproxy_service    = var.haproxy_service_name
      keepalived_service = var.keepalived_service_name
      haproxy_config     = local.haproxy_configs[key]
      keepalived_config  = local.keepalived_configs[key]
    })
  }

  hook_scripts = {
    for key, inst in local.instances : key => <<-EOT
      #!/bin/sh
      set -eu

      vmid="$1"
      phase="$2"

      if [ "$phase" != "post-start" ]; then
        exit 0
      fi

      attempts=0
      until pct exec "$vmid" -- sh -lc 'true' >/dev/null 2>&1; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 30 ]; then
          echo "container $vmid did not become ready for pct exec" >&2
          exit 1
        fi
        sleep 2
      done

      pct exec "$vmid" -- sh -lc 'install -d -m 0755 /usr/local/sbin'
      pct exec "$vmid" -- sh -lc 'printf %s '"'"'${base64encode(local.bootstrap_scripts[key])}'"'"' | base64 -d >/usr/local/sbin/k8s-api-lb-bootstrap.sh
chmod 0755 /usr/local/sbin/k8s-api-lb-bootstrap.sh
sh /usr/local/sbin/k8s-api-lb-bootstrap.sh'
    EOT
  }

  vip_address_only = split("/", var.vip_address)[0]
}
