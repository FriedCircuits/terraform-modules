locals {
  container_name      = var.name
  controller_version  = coalesce(var.controller_version, trimspace(file("${path.module}/CONTROLLER_VERSION")))
  mqtt_schema_version = coalesce(var.mqtt_schema_version, trimspace(file("${path.module}/MQTT_SCHEMA_VERSION")))
  description = coalesce(
    var.description,
    format("Shutdown controller %s", var.name)
  )

  controller_script_content = coalesce(var.controller_script, file("${path.module}/templates/controller.sh.tftpl"))
  recovery_script_content   = file("${path.module}/templates/recovery.sh.tftpl")

  controller_env = templatefile("${path.module}/templates/controller.env.tftpl", {
    controller_name                             = var.name
    controller_version                          = local.controller_version
    mqtt_schema_version                         = local.mqtt_schema_version
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

    hook_log="/var/log/shutdown-controller-hook.log"
    log() {
      printf '%s shutdown-controller-hook: %s\n' "$(date -Iseconds)" "$*" >>"$hook_log"
    }

    vmid="$1"
    phase="$2"

    log "invoked vmid=$vmid phase=$phase"

    if [ "$phase" != "post-start" ]; then
      log "skipping non-post-start phase"
      exit 0
    fi

    attempts=0
    until pct exec "$vmid" -- sh -lc 'true' >/dev/null 2>&1; do
      attempts=$((attempts + 1))
      if [ "$attempts" -ge 30 ]; then
        log "container $vmid did not become ready for pct exec"
        echo "container $vmid did not become ready for pct exec" >&2
        exit 1
      fi
      sleep 2
    done

    log "container ready for pct exec"

    bootstrap_file="$(pvesm path '${proxmox_virtual_environment_file.bootstrap_script.id}')"
    if [ -z "$bootstrap_file" ] || [ ! -f "$bootstrap_file" ]; then
      log "bootstrap snippet not found at resolved path: $bootstrap_file"
      echo "shutdown-controller bootstrap snippet not found" >&2
      exit 1
    fi

    log "resolved bootstrap snippet path: $bootstrap_file"

    log "scheduling async bootstrap apply"
    nohup sh -s "$vmid" "$bootstrap_file" <<'HOOK_APPLY' >/dev/null 2>&1 &
vmid="$1"
bootstrap_file="$2"
hook_log="/var/log/shutdown-controller-hook.log"

log() {
  printf '%s shutdown-controller-hook: %s\n' "$(date -Iseconds)" "$*" >>"$hook_log"
}

sleep 5

log "async apply starting vmid=$vmid bootstrap_file=$bootstrap_file"

pct exec "$vmid" -- sh -lc 'install -d -m 0755 /usr/local/sbin'

log "async apply pushing bootstrap into container"
pct push "$vmid" "$bootstrap_file" /usr/local/sbin/shutdown-controller-bootstrap.sh

log "async apply executing bootstrap inside container"
pct exec "$vmid" -- sh -lc 'chmod 0755 /usr/local/sbin/shutdown-controller-bootstrap.sh
BOOTSTRAP_LOG_FILE=/var/log/shutdown-controller-bootstrap.log /usr/local/sbin/shutdown-controller-bootstrap.sh'

log "async apply completed successfully"
HOOK_APPLY

    log "async bootstrap apply scheduled"
  EOT
}
