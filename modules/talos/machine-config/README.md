# Talos machine configuration

Apply a complete existing-cluster configuration to **one** Talos node using the
Sidero Labs provider. This module manages configuration only; it does not create
cluster secrets, bootstrap etcd, provision hardware, upgrade Talos, drain nodes,
or orchestrate storage migrations.

Requirements: Terraform >= 1.11 and Talos provider 0.11.x. Supply an existing
admin client certificate with `os:admin`, signed by the existing cluster Talos CA.
The worker config contains public CA certificates and empty CA private keys;
client credentials are a separate input, not the worker's CA keys.

```hcl
module "node" {
  source = "../modules/talos/machine-config"
  node = var.node_address
  machine_configuration = file(var.machine_configuration_path)
  client_configuration = var.talos_admin_client
  # Default no_reboot rejects changes that require a reboot.
}
```

Declare the caller's `talos_admin_client` variable as sensitive and ephemeral.
The module uses the provider's write-only client argument. Machine configuration
itself is sensitive but remains in Terraform state, so use encrypted remote state
and restrict access to it and saved plans. Sensitive marking hides values in
normal output; it is not encryption.

Use one state per node and review each plan before applying. A first apply adopts
management by sending the desired config again; do not treat it as a read-only
import. Compare the desired config to the running config before adoption. This
resource does not provide authoritative live drift detection; the output hash is
of desired input only. Continue using Talos readback/health checks.

The default `no_reboot` mode is intended for running nodes. For a reflashed
maintenance-mode node, use the recovery `talosctl apply-config --insecure` flow,
then adopt the configured node here with authenticated access. Explicit `auto`
or `reboot` is available for planned maintenance. Changing a VolumeConfig does
not migrate existing partitions or data; handle storage migration separately. `machine.install.image` changes are not an OS upgrade operation.

Destroy is explicitly configured as a no-op on the node (`reset = false`).

Validation: `terraform init -backend=false`, `terraform validate`, and
`terraform test` (mock provider; no node calls).
