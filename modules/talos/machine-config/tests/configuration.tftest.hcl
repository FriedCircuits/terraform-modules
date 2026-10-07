mock_provider "talos" {}

variables {
  node                  = "192.0.2.10"
  machine_configuration = <<-YAML
    version: v1alpha1
    machine:
      type: worker
    ---
    apiVersion: v1alpha1
    kind: VolumeConfig
    name: EPHEMERAL
    provisioning:
      minSize: 8GiB
      maxSize: 8GiB
    ---
    apiVersion: v1alpha1
    kind: RawVolumeConfig
    name: data
    provisioning:
      minSize: 16GiB
      grow: true
  YAML
  client_configuration = {
    ca_certificate     = "fixture-ca"
    client_certificate = "fixture-cert"
    client_key         = "fixture-key"
  }
}

run "single_node_defaults" {
  command = plan
  assert {
    condition     = talos_machine_configuration_apply.this.endpoint == var.node
    error_message = "The endpoint must default to the managed node."
  }
  assert {
    condition     = talos_machine_configuration_apply.this.apply_mode == "no_reboot" && talos_machine_configuration_apply.this.on_destroy.reset == false
    error_message = "The default must reject reboots and never reset on destroy."
  }
  assert {
    condition     = talos_machine_configuration_apply.this.machine_configuration_input == var.machine_configuration
    error_message = "All configuration documents must reach the provider unchanged."
  }
}

run "explicit_maintenance_mode" {
  command = plan
  variables {
    endpoint   = "192.0.2.11"
    apply_mode = "auto"
  }
  assert {
    condition     = talos_machine_configuration_apply.this.endpoint == "192.0.2.11" && talos_machine_configuration_apply.this.apply_mode == "auto"
    error_message = "Explicit endpoint and maintenance mode must be honored."
  }
}

run "invalid_mode" {
  command = plan
  variables {
    apply_mode = "staged"
  }
  expect_failures = [var.apply_mode]
}
