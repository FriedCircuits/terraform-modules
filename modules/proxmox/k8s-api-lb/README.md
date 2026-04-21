# Proxmox Kubernetes API Load Balancer

This module provisions 2-3 Proxmox LXCs running HAProxy and Keepalived outside the cluster so a Talos or Kubernetes control plane can be exposed through a stable VRRP virtual IP.

## Features

- Uses the `bpg/proxmox` provider with typed inputs.
- Supports 2 or 3 load balancer nodes.
- Downloads an LXC template to each target Proxmox node when needed.
- Renders HAProxy and Keepalived configuration from Terraform templates.
- Bootstraps packages and configuration through a Proxmox hook script.
- Installs a container-safe HAProxy systemd unit so the service starts reliably inside LXC.
- Can optionally expose the Talos API on the same VIP through HAProxy port `50000`.

## Example

```hcl
module "k8s_api_lb" {
  source = "git::https://github.com/friedcircuits/terraform-modules.git//modules/proxmox/k8s-api-lb?ref=main"

  name_prefix    = "k8s-api-lb"
  vip_address    = "192.168.1.42/24"
  vip_dns_name   = "k8s-api.example.com"
  vrrp_auth_pass = var.k8s_api_lb_vrrp_auth_pass

  control_plane_backends = [
    {
      name = "cp01"
      ip   = "192.168.1.101"
      port = 6443
    },
    {
      name = "cp02"
      ip   = "192.168.1.102"
      port = 6443
    },
    {
      name = "cp03"
      ip   = "192.168.1.103"
      port = 6443
    }
  ]

  talos_api = {
    enabled = true
  }

  instances = {
    lb01 = {
      node_name    = "pve1"
      vm_id        = 2100
      ipv4_address = "192.168.1.21/24"
      gateway      = "192.168.1.1"
      priority     = 120
    }
    lb02 = {
      node_name    = "pve2"
      vm_id        = 2101
      ipv4_address = "192.168.1.22/24"
      gateway      = "192.168.1.1"
      priority     = 110
    }
  }

  dns = {
    domain  = "example.com"
    servers = ["192.168.1.1"]
  }

  container_template = {
    url          = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
    datastore_id = "local"
    type         = "debian"
  }

  snippet_datastore_id = "local"

  root_public_keys = [file("~/.ssh/id_ed25519.pub")]

  pve_connection = {
    endpoint     = "https://pve.example.com:8006"
    api_user     = "terraform@pam"
    api_password = var.proxmox_password
  }
}
```

## Important Notes

- `instances` must contain 2 or 3 entries.
- Set each instance `ipv4_address` and `vip_address` to match the actual network CIDR for the subnet that carries the VIP. For example, use `/23` on a `/23` network and `/24` on a `/24` network.
- `vrrp_auth_pass` is limited to 8 characters because Keepalived PASS authentication inherits the VRRP protocol limit.
- `snippet_datastore_id` must point at a Proxmox storage that supports `snippets`.
- Prefer `root_public_keys` for guest access. `root_password` is supported but should be used only when keys are not practical.
- By default the containers are privileged because VRRP VIP management is more reliable in that mode.
- Proxmox API TLS verification is enabled by default. Set `pve_connection.tls_insecure = true` only if your environment requires it.
- When `container_template.file_id` is not supplied, the module downloads the template to each Proxmox node referenced by `instances`.
- The first container boot is handled by a Proxmox hook script. Package auto-start is explicitly suppressed during bootstrap so the packaged HAProxy unit does not race the container-safe replacement unit.

## Inputs

- `name_prefix`: Prefix used to generate hostnames and snippet names.
- `vip_address`: VRRP VIP in CIDR notation.
- `vip_dns_name`: DNS name that should resolve to the VIP.
- `vrrp_auth_pass`: Keepalived authentication password.
- `control_plane_backends`: API backends rendered into HAProxy.
- `talos_api`: Optional Talos API listener configuration. When enabled without custom backends, it reuses the control-plane backend IPs on port `50000`.
- `instances`: Map of LXC nodes, including target Proxmox node and static IPv4 settings.
- `container_template`: Existing LXC template file ID or a URL to download per node.
- `dns`: Optional DNS search domain and nameservers.
- `root_public_keys`: Optional SSH public keys installed for the root account inside each container.
- `root_password`: Optional root password for each container.
- `pve_connection`: Proxmox endpoint and credentials.

## Outputs

- `vip_address`: Virtual IP address in CIDR notation.
- `vip_ip`: Virtual IP address without CIDR mask.
- `vip_dns_name`: DNS name intended to resolve to the VIP.
- `container_vm_ids`: Proxmox VMIDs keyed by instance name.
- `container_names`: Container hostnames keyed by instance name.
- `container_ipv4_addresses`: Configured IPv4 addresses keyed by instance name.
- `container_ipv4_reported`: IPv4 addresses reported by Proxmox for each container.