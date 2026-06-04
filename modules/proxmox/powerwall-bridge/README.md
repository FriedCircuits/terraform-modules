# Proxmox Powerwall Bridge

Creates a Proxmox LXC that runs the upstream `pyPowerwall` proxy and, optionally, an MQTT publisher for Home Assistant.

Uses the sibling `../lxc` module for the base container.

## Services

Inside the container:

- `powerwall-proxy.service`: runs the upstream `pyPowerwall` HTTP proxy on port `8675`
- `powerwall-mqtt-publisher.service`: polls the local proxy and publishes MQTT discovery and retained state snapshots

If MQTT publishing is disabled, the proxy still runs and can be consumed directly over HTTP.

Useful proxy endpoints:

- `/aggregates`
- `/soe`
- `/strings`
- `/vitals`
- `/alerts`
- `/alerts/pw`
- `/health`

## Host Requirements

This module does not set up the Proxmox host-side path to the Powerwall. It does not configure:

- host Wi-Fi association to the Powerwall access point
- host IP forwarding
- host NAT or firewall policy
- Linux bridge design on the Proxmox host

If your container reaches the Powerwall through the Proxmox host, host-side routing or NAT is required. A guest-side route alone is not sufficient.

This repository does not currently include a public, reusable Ansible role for that host-side setup.

Typical flow:

1. The Proxmox host reaches the Powerwall.
2. The container uses normal LAN networking for management and MQTT.
3. `route_to_powerwall` sends Powerwall traffic to the Proxmox host as the next hop when needed.

For Wi-Fi TEDAPI access:

1. Attach the Proxmox host to the Powerwall Wi-Fi network.
2. Verify the host can reach `192.168.91.1` reliably.
3. Enable host forwarding or NAT from the LXC network toward the Powerwall Wi-Fi interface.
4. Set `route_to_powerwall.gateway` to the Proxmox host IP as seen by the container.

Without that host-side forwarding or NAT path, the bridge container will not be able to reach the Powerwall even if `route_to_powerwall` is configured.

Firmware caveat:

- Recent Powerwall firmware may block routed TEDAPI access even if the route exists.
- In that case the host path still has to work first. `route_to_powerwall` is only a guest-side convenience.

## Connectivity Modes

This module passes connection settings through to pyPowerwall.

Typical Powerwall 3 cases:

- Wi-Fi TEDAPI with string metrics:
  - `powerwall.host = "192.168.91.1"`
  - `powerwall.gw_password` required
- Wired vendor-subnet v1r access:
  - `powerwall.host = "10.42.1.x"`
  - `powerwall.gw_password` required
  - `powerwall.rsa_key_content` required for the full control-style path
- Cloud-oriented setup:
  - set `powerwall.email`
  - follow upstream pyPowerwall guidance if you need cloud-only behaviors

## Example

See [examples/basic](examples/basic) for a minimal standalone configuration.

It only covers the Terraform side. You still need to build the Proxmox host-side connectivity yourself.

## Usage

```hcl
module "powerwall_bridge" {
  source = "git::https://github.com/friedcircuits/terraform-modules.git//modules/proxmox/powerwall-bridge?ref=v0.1.0"

  name      = "powerwall3-bridge"
  node_name = "pve3"
  vm_id     = 1450

  container_template = {
    file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    type    = "debian"
  }

  dns = {
    domain  = "example.internal"
    servers = ["192.168.0.1"]
  }

  root_public_keys = [file("~/.ssh/id_ed25519.pub")]

  timezone = "UTC"

  powerwall = {
    host        = "192.168.91.1"
    gw_password = var.powerwall_gateway_password
  }

  mqtt = {
    host             = "mqtt.example.internal"
    topic_prefix     = "powerwall/powerwall3-bridge"
    discovery_prefix = "homeassistant"
  }

  mqtt_credentials = {
    username = var.mqtt_username
    password = var.mqtt_password
  }

  route_to_powerwall = {
    gateway = "192.168.1.32"
  }

  mqtt_fetch_timeout_seconds     = 15
  mqtt_fetch_retries             = 2
  mqtt_fetch_retry_delay_seconds = 1.5
  mqtt_failures_before_offline   = 5

  pve_connection = {
    endpoint     = "https://pve.example.com:8006"
    api_user     = "terraform@pam"
    api_password = var.proxmox_password
  }
}
```

## MQTT and Home Assistant

When MQTT is enabled, the publisher creates one Home Assistant device and publishes a retained state payload at the configured interval.

Current entity groups:


- site telemetry: grid, home, solar, battery power, battery level, reserve, mode, grid status, firmware version
- alerts: active alert count and summary, gateway alert count and summary, pack alert count and summary
- solar strings: per-string power, voltage, current, state, connected status
- battery blocks: power, voltage, frequency, inverter state, grid state, remaining/full energy, disabled reasons, disabled/backup-ready/off-grid state
- inverter and sync vitals: inverter power, voltage, split voltages, frequency, state, sync grid connected/state, gateway location
- fan data when present

The exact data available still depends on model, firmware, and which API path works in your setup.

## Validation

Plan-time validation covers:

- Proxmox authentication method selection
- valid proxy and MQTT ports
- non-empty MQTT and Powerwall credential fields when set
- `powerwall.rsa_key_content` requiring `powerwall.gw_password`
- route gateway formatting
- non-negative publisher retry and backoff settings

This catches common bad input combinations, not end-to-end networking mistakes.

## Operational Notes

- The bootstrap process clones and pins the upstream pyPowerwall repository inside the container.
- The MQTT publisher depends on the local proxy, not on direct Powerwall access.
- `route_to_powerwall` only installs a route inside the guest.
- Routed access requires a separately managed host-side forwarding or NAT design.
- The default timezone is `UTC`; set `timezone` explicitly if you want local timestamps in another zone.
- The MQTT publisher retry and offline thresholds are configurable without editing templates.
- MQTT discovery is retained, so changing the publisher model may require the bridge to republish or clear deprecated entities.
- Some upstream metrics are firmware- and model-dependent. For example, Powerwall 3 temperature data may not be available from the TEDAPI controller path even when older systems expose it.