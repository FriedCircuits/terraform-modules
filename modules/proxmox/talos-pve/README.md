# Talos Control Plane VMs (Proxmox)

This module provisions one or more Talos control plane VMs on Proxmox using a pre-built Talos factory ISO. It downloads the ISO into a datastore, uploads optional NoCloud payloads, and creates a VM for each entry in the `instances` map.

## Usage

```hcl
module "talos_control_plane" {
  source = "../modules/talos-pve"

  default_vm_specs = {
    cpu_cores    = 4
    cpu_sockets  = 1
    cpu_type     = "host"
    memory_mb    = 8192
    disk_size_gb = 50
    bios_type    = "ovmf"
  }

  default_proxmox_network = {
    bridge = "vmbr0"
  }

  default_tags = ["talos", "control-plane"]
  default_disk_interface = "virtio0"

  instances = {
    cp01 = {
      name         = "talos-cp-01"
      proxmox_node = "pve1"
      vm_id        = 1100
      iso_url      = "https://factory.talos.dev/image/.../nocloud-amd64.iso"
      additional_disks = [
        {
          datastore_id = "ceph-ssd"
          interface    = "scsi1"
          size_gb      = 100
          ssd          = true
        }
      ]
      cloud_init = {
        datastore_id = "local"
        user_data    = file("controlplane01.yaml")
      }
    }
    cp02 = {
      proxmox_node = "pve1"
      vm_id        = 1101
      iso_url      = "https://factory.talos.dev/image/.../nocloud-amd64.iso"
      cloud_init = {
        datastore_id = "local"
        user_data    = file("controlplane02.yaml")
      }
    }
  }

  pve_connection = {
    node         = "pve1"
    endpoint     = "https://pve1.example.internal:8006"
    api_user     = "terraform@pam"
    api_password = var.proxmox_password
  }
}
```

```

To reuse an ISO that was already uploaded (for example, by the control-plane deployment) set `skip_iso_download = true` and provide `existing_iso_file_id` with the file ID you want to attach:

```hcl
instances = {
  worker01 = {
    proxmox_node         = "pve1"
    vm_id                = 1200
    skip_iso_download    = true
    existing_iso_file_id = var.control_plane_iso_file_ids["cp01"]
    iso_url              = "https://factory.talos.dev/image/.../nocloud-amd64.iso" # unused when skipping download
    cloud_init = {
      datastore_id = "local"
      user_data    = file("worker01.yaml")
    }
  }
}
```

You can also enforce this behaviour for every instance by setting `default_skip_iso_download = true` and supplying `default_existing_iso_file_id` (individual instances can still override either value).

## Inputs (selected)

- `instances` – Map of control plane nodes to create (name, target node, ISO URL, optional overrides, disk interface, BIOS type, optional reuse of existing ISO file IDs, extra disks, USB pass-through, cloud-init payloads, etc.).
- `default_skip_iso_download`, `default_existing_iso_file_id` – module-wide defaults for reusing an already-uploaded ISO when per-instance values are omitted.
- `default_vm_specs`, `default_disk_storage`, `default_disk_interface`, `default_iso_storage`, `default_proxmox_network`, `default_tags`, `default_enable_rng`, `default_description_prefix` – baseline settings applied when an instance omits a value (including `bios_type` when set).
- `pve_connection` – Proxmox API connection details (node, endpoint, and credentials).

## Outputs

- `vm_ids` – Map of VMIDs keyed by instance name.
- `vm_names` – Map of VM names keyed by instance name.
- `iso_file_ids` – Map of ISO file IDs keyed by instance name.

Supply Talos factory ISOs that already contain the desired machine configuration (e.g. generated with Talos Factory). Optional NoCloud payloads can still be uploaded via the `cloud_init` field for additional customization.

When `cloud_init.user_data` is provided, the module patches the YAML so that `machine.network.hostname` defaults to the VM name (unless you already set a hostname in the payload).
