locals {
  container_name = var.name
  description = coalesce(
    var.description,
    format("Shutdown controller %s", var.name)
  )

  controller_script_content = coalesce(var.controller_script, file("${path.module}/templates/controller.sh.tftpl"))
  recovery_script_content   = file("${path.module}/templates/recovery.sh.tftpl")

  controller_env = templatefile("${path.module}/templates/controller.env.tftpl", {
    controller_name                             = var.name
    kubeconfig_path                             = "/etc/shutdown-controller/kubeconfig"
    talosconfig_path                            = "/etc/shutdown-controller/talosconfig"
    ceph_namespace                              = coalesce(try(var.ceph.namespace, null), "rook-ceph")
    ceph_tools_deployment                       = coalesce(try(var.ceph.tools_deployment, null), "rook-ceph-tools")
    nut                                         = var.nut
    nut_server_port                             = var.nut != null ? coalesce(try(var.nut.server_port, null), 3493) : 3493
    nut_credentials                             = var.nut_credentials
    mqtt                                        = var.mqtt
    mqtt_port                                   = var.mqtt != null ? coalesce(try(var.mqtt.port, null), 1883) : 1883
    mqtt_topic_prefix                           = var.mqtt != null ? coalesce(try(var.mqtt.topic_prefix, null), format("homelab/%s", var.name)) : format("homelab/%s", var.name)
    mqtt_client_id                              = var.mqtt != null ? coalesce(try(var.mqtt.client_id, null), var.name) : var.name
    mqtt_retain_status                          = var.mqtt != null ? coalesce(try(var.mqtt.retain_status, null), true) : true
    mqtt_discovery_prefix                       = var.mqtt != null ? coalesce(try(var.mqtt.discovery_prefix, null), "homeassistant") : "homeassistant"
    mqtt_enable_ha_discovery                    = var.mqtt != null ? coalesce(try(var.mqtt.enable_ha_discovery, null), true) : true
    mqtt_credentials                            = var.mqtt_credentials
    talos_nodes                                 = join(",", var.talos_nodes)
    linux_shutdown_targets_b64                  = base64encode(jsonencode(var.linux_shutdown_targets))
    linux_shutdown_ssh_user                     = var.linux_shutdown_ssh != null ? coalesce(try(var.linux_shutdown_ssh.user, null), "root") : "root"
    linux_shutdown_ssh_port                     = var.linux_shutdown_ssh != null ? coalesce(try(var.linux_shutdown_ssh.port, null), 22) : 22
    linux_shutdown_ssh_strict_host_key_checking = var.linux_shutdown_ssh != null ? coalesce(try(var.linux_shutdown_ssh.strict_host_key_checking, null), "accept-new") : "accept-new"
    proxmox_nodes                               = join(",", var.proxmox_nodes)
    pve_api                                     = var.pve_api
    pve_api_tls_insecure                        = var.pve_api != null ? coalesce(try(var.pve_api.tls_insecure, null), false) : false
    extra_env                                   = var.controller_environment
  })

  systemd_unit = templatefile("${path.module}/templates/shutdown-controller.service.tftpl", {
    env_file        = "/etc/shutdown-controller/controller.env"
    controller_path = "/usr/local/sbin/shutdown-controller"
  })

  recovery_systemd_unit = templatefile("${path.module}/templates/shutdown-controller-recovery.service.tftpl", {
    env_file      = "/etc/shutdown-controller/controller.env"
    recovery_path = "/usr/local/sbin/shutdown-controller-recovery"
  })

  bootstrap_script = templatefile("${path.module}/templates/bootstrap.sh.tftpl", {
    packages                           = join(" ", var.packages)
    kubectl_version                    = var.kubectl_version
    talosctl_version                   = var.talosctl_version
    controller_env_b64                 = base64encode(local.controller_env)
    controller_script_b64              = base64encode(local.controller_script_content)
    recovery_script_b64                = base64encode(local.recovery_script_content)
    systemd_unit_b64                   = base64encode(local.systemd_unit)
    recovery_systemd_unit_b64          = base64encode(local.recovery_systemd_unit)
    kubeconfig_b64                     = var.kubeconfig_content != null ? base64encode(var.kubeconfig_content) : ""
    talosconfig_b64                    = var.talosconfig_content != null ? base64encode(var.talosconfig_content) : ""
    linux_shutdown_ssh_private_key_b64 = var.linux_shutdown_ssh != null ? base64encode(var.linux_shutdown_ssh.private_key_content) : ""
    linux_shutdown_known_hosts_b64     = var.linux_shutdown_ssh != null && try(var.linux_shutdown_ssh.known_hosts_content, null) != null ? base64encode(var.linux_shutdown_ssh.known_hosts_content) : ""
    write_kubeconfig                   = var.kubeconfig_content != null
    write_talosconfig                  = var.talosconfig_content != null
    write_linux_shutdown_ssh_key       = var.linux_shutdown_ssh != null
    write_linux_shutdown_known_hosts   = var.linux_shutdown_ssh != null && try(var.linux_shutdown_ssh.known_hosts_content, null) != null
    enable_controller_service          = var.enable_controller_service
    enable_recovery_service            = var.enable_recovery_service
  })

  hook_script = <<-EOT
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
    pct exec "$vmid" -- sh -lc 'printf %s '"'"'${base64encode(local.bootstrap_script)}'"'"' | base64 -d >/usr/local/sbin/shutdown-controller-bootstrap.sh
chmod 0755 /usr/local/sbin/shutdown-controller-bootstrap.sh
sh /usr/local/sbin/shutdown-controller-bootstrap.sh'
  EOT
}
