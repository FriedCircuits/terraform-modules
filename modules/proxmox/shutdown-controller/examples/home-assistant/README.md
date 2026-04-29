# Home Assistant Examples

These files are optional examples for the shutdown-controller module.

They assume the module is using the default controller name of `shutdown-controller`, which produces entity IDs like:

- `binary_sensor.shutdown_controller_ups_connected`
- `binary_sensor.shutdown_controller_on_battery`
- `binary_sensor.shutdown_controller_ceph_noout_set`
- `binary_sensor.shutdown_controller_talos_shutdown_started`
- `binary_sensor.shutdown_controller_linux_shutdown_started`
- `binary_sensor.shutdown_controller_proxmox_shutdown_started`
- `sensor.shutdown_controller_ups_status`
- `sensor.shutdown_controller_ups_runtime`
- `sensor.shutdown_controller_ups_runtime_formatted`
- `sensor.shutdown_controller_ups_charge`
- `sensor.shutdown_controller_mode`
- `sensor.shutdown_controller_recovery_status`
- `sensor.shutdown_controller_last_event`

If you change `name` in the Terraform module, update these examples to match the discovered entity IDs in your Home Assistant instance.

The raw runtime entity (`sensor.shutdown_controller_ups_runtime`) is kept for automations and debugging, but it is disabled by default in Home Assistant discovery. Enable it from the device page if you want the seconds value exposed in the UI.

If Home Assistant already discovered the older duplicated IDs, it will keep those entity IDs because they are stored in the entity registry by `unique_id`. Re-publishing discovery alone will not rename them.

To move to the clean IDs, remove the old MQTT device or those specific entity registry entries in Home Assistant, then let the controller republish its retained discovery topics.

Older retained discovery payloads at the broker can briefly recreate the stale entities before the controller publishes updated config. The module now clears the retained discovery topics once when its discovery schema version changes, then republishes the new config.

## Files

- [automations.yaml](automations.yaml): example persistent-notification automations
- [package.yaml](package.yaml): an all-in-one package with derived sensors, alerting, and a helper group
- [dashboard.yaml](dashboard.yaml): a manual Lovelace card stack for the discovered entities

## Usage

For standalone automations:

1. Copy the contents of [automations.yaml](automations.yaml) into your Home Assistant automations.
2. Reload automations or restart Home Assistant.

For package users:

1. Save [package.yaml](package.yaml) under your Home Assistant packages directory, for example `packages/shutdown_controller.yaml`.
2. Ensure packages are enabled in your Home Assistant configuration.
3. Reload YAML configuration or restart Home Assistant.

For dashboards:

1. Open a dashboard in Home Assistant.
2. Add a Manual card.
3. Paste the contents of [dashboard.yaml](dashboard.yaml).
