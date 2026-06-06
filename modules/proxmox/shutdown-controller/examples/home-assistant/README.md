# Home Assistant Examples

These files are optional examples for the shutdown-controller module.

They assume the module is using the default controller name of `shutdown-controller`, which produces entity IDs like:

- `binary_sensor.shutdown_controller_ups_connected`
- `binary_sensor.shutdown_controller_on_battery`
- `binary_sensor.shutdown_controller_incident_active`
- `binary_sensor.shutdown_controller_failure_active`
- `binary_sensor.shutdown_controller_recovery_pending`
- `binary_sensor.shutdown_controller_ceph_noout_set`
- `binary_sensor.shutdown_controller_talos_shutdown_started`
- `binary_sensor.shutdown_controller_linux_shutdown_started`
- `binary_sensor.shutdown_controller_proxmox_shutdown_started`
- `sensor.shutdown_controller_ups_status`
- `sensor.shutdown_controller_ups_runtime`
- `sensor.shutdown_controller_ups_runtime_formatted`
- `sensor.shutdown_controller_ups_charge`
- `sensor.shutdown_controller_controller_version`
- `sensor.shutdown_controller_mqtt_schema_version`
- `sensor.shutdown_controller_mode`
- `sensor.shutdown_controller_phase`
- `sensor.shutdown_controller_failure_code`
- `sensor.shutdown_controller_failure_message`
- `sensor.shutdown_controller_failure_severity`
- `sensor.shutdown_controller_failure_at`
- `sensor.shutdown_controller_incident_status`
- `sensor.shutdown_controller_incident_started_at`
- `sensor.shutdown_controller_incident_ended_at`
- `sensor.shutdown_controller_incident_power_restored_at`
- `sensor.shutdown_controller_incident_duration_seconds`
- `sensor.shutdown_controller_incident_duration_formatted`
- `sensor.shutdown_controller_incident_trigger_reason`
- `sensor.shutdown_controller_incident_trigger_runtime`
- `sensor.shutdown_controller_incident_trigger_charge`
- `sensor.shutdown_controller_recovery_status`
- `sensor.shutdown_controller_recovery_blocker`
- `sensor.shutdown_controller_recovery_elapsed_seconds`
- `sensor.shutdown_controller_recovery_elapsed_formatted`
- `sensor.shutdown_controller_last_event`
- `sensor.shutdown_controller_last_event_at`
- `sensor.shutdown_controller_last_message`
- `sensor.shutdown_controller_last_action`
- `sensor.shutdown_controller_last_action_target`
- `sensor.shutdown_controller_last_action_result`
- `sensor.shutdown_controller_last_action_at`
- `sensor.shutdown_controller_last_completed_status`
- `sensor.shutdown_controller_last_completed_started_at`
- `sensor.shutdown_controller_last_completed_ended_at`
- `sensor.shutdown_controller_last_completed_power_restored_at`
- `sensor.shutdown_controller_last_completed_duration_formatted`
- `sensor.shutdown_controller_last_completed_trigger_reason`
- `sensor.shutdown_controller_last_completed_last_action`
- `sensor.shutdown_controller_last_completed_at`

If you change `name` in the Terraform module, update these examples to match the discovered entity IDs in your Home Assistant instance.

The raw runtime entity (`sensor.shutdown_controller_ups_runtime`) and some raw duration counters are kept for automations and InfluxDB/Grafana analysis, but they are disabled by default in Home Assistant discovery when the formatted equivalents are the better day-to-day UI.

The current model is split on purpose:

- live state entities answer what the controller is doing right now
- last completed entities answer what the most recent finished power event looked like

The examples now include the full current discovery surface. Some entities are more useful for operations and automations than for a day-to-day dashboard, but they are listed here so you can decide what to expose in your own UI.

The richer incident entities are meant to answer two operational questions without opening logs:

- why the shutdown flow started
- what blocked or completed recovery afterward

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
