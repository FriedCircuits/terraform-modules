locals {
  container_name = var.name
  sanitized_name = replace(var.name, ".", "-")
  description = coalesce(
    var.description,
    format("Powerwall bridge %s", var.name)
  )

  powerwall_host              = coalesce(try(var.powerwall.host, null), "192.168.91.1")
  powerwall_gateway_password  = try(var.powerwall.gw_password, null)
  powerwall_customer_password = try(var.powerwall.password, null)
  powerwall_email             = try(var.powerwall.email, null)
  powerwall_wifi_host         = try(var.powerwall.wifi_host, null)
  powerwall_write_rsa_key     = try(var.powerwall.rsa_key_content, null) != null
  powerwall_route_destination = var.route_to_powerwall != null ? coalesce(try(var.route_to_powerwall.destination, null), "192.168.91.1/32") : null
  powerwall_route_interface   = var.route_to_powerwall != null ? coalesce(try(var.route_to_powerwall.interface, null), var.network_interface_name) : null
  powerwall_route_gateway     = var.route_to_powerwall != null ? var.route_to_powerwall.gateway : null
  powerwall_route_onlink      = var.route_to_powerwall != null ? coalesce(try(var.route_to_powerwall.onlink, null), true) : false
  mqtt_topic_prefix           = var.mqtt != null ? coalesce(try(var.mqtt.topic_prefix, null), format("homelab/%s", var.name)) : format("homelab/%s", var.name)
  mqtt_discovery_prefix       = var.mqtt != null ? coalesce(try(var.mqtt.discovery_prefix, null), "homeassistant") : "homeassistant"
  mqtt_port                   = var.mqtt != null ? coalesce(try(var.mqtt.port, null), 1883) : 1883
  mqtt_client_id              = var.mqtt != null ? coalesce(try(var.mqtt.client_id, null), format("%s-mqtt", local.sanitized_name)) : format("%s-mqtt", local.sanitized_name)
  mqtt_retain                 = var.mqtt != null ? coalesce(try(var.mqtt.retain, null), true) : true

  proxy_env = templatefile("${path.module}/templates/powerwall-proxy.env.tftpl", {
    timezone                       = var.timezone
    proxy_bind_address             = var.proxy_bind_address
    proxy_port                     = var.proxy_port
    proxy_https_mode               = var.proxy_https_mode
    proxy_cache_expire             = var.proxy_cache_expire
    proxy_cache_ttl                = var.proxy_cache_ttl
    proxy_timeout                  = var.proxy_timeout
    proxy_pool_maxsize             = var.proxy_pool_maxsize
    proxy_fail_fast                = var.proxy_fail_fast
    proxy_graceful_degradation     = var.proxy_graceful_degradation
    proxy_health_check             = var.proxy_health_check
    proxy_suppress_network_errors  = var.proxy_suppress_network_errors
    proxy_network_error_rate_limit = var.proxy_network_error_rate_limit
    powerwall_host                 = local.powerwall_host
    powerwall_gateway_password     = local.powerwall_gateway_password
    powerwall_customer_password    = local.powerwall_customer_password
    powerwall_email                = local.powerwall_email
    powerwall_wifi_host            = local.powerwall_wifi_host
    write_rsa_key                  = local.powerwall_write_rsa_key
    rsa_key_path                   = "/etc/powerwall-bridge/tedapi_rsa_private.pem"
  })

  mqtt_env = var.mqtt != null ? templatefile("${path.module}/templates/powerwall-mqtt.env.tftpl", {
    proxy_port                       = var.proxy_port
    mqtt_host                        = var.mqtt.host
    mqtt_port                        = local.mqtt_port
    mqtt_topic_prefix                = local.mqtt_topic_prefix
    mqtt_discovery_prefix            = local.mqtt_discovery_prefix
    mqtt_client_id                   = local.mqtt_client_id
    mqtt_retain                      = local.mqtt_retain
    mqtt_publish_interval_seconds    = var.mqtt_publish_interval_seconds
    mqtt_status_log_interval_seconds = var.mqtt_status_log_interval_seconds
    mqtt_failures_before_offline     = var.mqtt_failures_before_offline
    mqtt_fetch_timeout_seconds       = var.mqtt_fetch_timeout_seconds
    mqtt_fetch_retries               = var.mqtt_fetch_retries
    mqtt_fetch_retry_delay_seconds   = var.mqtt_fetch_retry_delay_seconds
    mqtt_credentials                 = var.mqtt_credentials
    device_id                        = local.sanitized_name
    device_name                      = var.name
  }) : null

  proxy_service_unit = templatefile("${path.module}/templates/powerwall-proxy.service.tftpl", {
    env_file = "/etc/powerwall-bridge/proxy.env"
  })

  mqtt_service_unit = var.mqtt != null ? templatefile("${path.module}/templates/powerwall-mqtt-publisher.service.tftpl", {
    env_file       = "/etc/powerwall-bridge/mqtt.env"
    publisher_path = "/usr/local/lib/powerwall-bridge/mqtt_publisher.py"
  }) : null

  route_service_unit = var.route_to_powerwall != null ? templatefile("${path.module}/templates/powerwall-route.service.tftpl", {
    destination = local.powerwall_route_destination
    gateway     = local.powerwall_route_gateway
    interface   = local.powerwall_route_interface
    onlink      = local.powerwall_route_onlink
  }) : null

  mqtt_publisher_script = var.mqtt != null ? templatefile("${path.module}/templates/mqtt_publisher.py.tftpl", {
    device_id        = local.sanitized_name
    device_name      = var.name
    proxy_port       = var.proxy_port
    topic_prefix     = local.mqtt_topic_prefix
    discovery_prefix = local.mqtt_discovery_prefix
  }) : null

  bootstrap_script = templatefile("${path.module}/templates/bootstrap.sh.tftpl", {
    packages                  = join(" ", var.packages)
    repo_ref                  = var.pypowerwall_repo_ref
    proxy_env_b64             = base64encode(local.proxy_env)
    proxy_service_unit_b64    = base64encode(local.proxy_service_unit)
    mqtt_env_b64              = local.mqtt_env != null ? base64encode(local.mqtt_env) : ""
    mqtt_service_unit_b64     = local.mqtt_service_unit != null ? base64encode(local.mqtt_service_unit) : ""
    mqtt_publisher_script_b64 = local.mqtt_publisher_script != null ? base64encode(local.mqtt_publisher_script) : ""
    route_service_unit_b64    = local.route_service_unit != null ? base64encode(local.route_service_unit) : ""
    rsa_key_b64               = local.powerwall_write_rsa_key ? base64encode(var.powerwall.rsa_key_content) : ""
    write_rsa_key             = local.powerwall_write_rsa_key
    enable_proxy_service      = var.enable_proxy_service
    enable_mqtt_publisher     = var.enable_mqtt_publisher && var.mqtt != null
    enable_route_service      = var.route_to_powerwall != null
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
    pct exec "$vmid" -- sh -lc 'printf %s '"'"'${base64encode(local.bootstrap_script)}'"'"' | base64 -d >/usr/local/sbin/powerwall-bridge-bootstrap.sh
chmod 0755 /usr/local/sbin/powerwall-bridge-bootstrap.sh
sh /usr/local/sbin/powerwall-bridge-bootstrap.sh'
  EOT
}
