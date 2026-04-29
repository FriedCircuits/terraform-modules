# Proxmox LXC

This module provisions a single Proxmox LXC container using the `bpg/proxmox` provider.

It is intentionally narrow and infrastructure-focused:

- create one container
- optionally download a container template on the target node
- optionally upload and attach a hook script snippet
- configure CPU, memory, disk, networking, startup, and basic guest initialization

This module is intended to be used directly for simple containers or wrapped by higher-level modules such as load balancers or controllers.

For multiple containers, prefer `for_each` on the calling module rather than baking multi-instance behavior into this module.

## Provider Ownership

This module intentionally does not define its own `provider "proxmox"` block.

That is a Terraform limitation rather than a Proxmox-specific requirement: child modules that define their own provider configuration become legacy modules, and callers can no longer use `for_each`, `count`, or `depends_on` on them.

In practice, that means the root module, or the Terragrunt-driven module at the top, should own the Proxmox provider configuration and pass normal inputs into this module. That keeps `lxc` reusable both for direct single-container use and for higher-level modules such as `k8s-api-lb`.

## Usage

```hcl
module "lxc" {
  source = "git::https://github.com/friedcircuits/terraform-modules.git//modules/proxmox/lxc?ref=v0.1.0"

  name         = "example-lxc"
  node_name    = "pve1"
  vm_id        = 1300
  ipv4_address = "dhcp"

  container_template = {
    file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    type    = "debian"
  }

  root_public_keys = [file("~/.ssh/id_ed25519.pub")]
  tags             = ["example", "lxc"]

  pve_connection = {
    endpoint     = "https://pve.example.com:8006"
    api_user     = "terraform@pam"
    api_password = var.proxmox_password
  }
}
```

## Multiple Containers

Use `for_each` in the caller when you need multiple containers:

```hcl
module "lxc" {
  for_each = {
    lb1 = {
      node_name    = "pve1"
      vm_id        = 1401
      ipv4_address = "192.168.1.41/24"
    }
    lb2 = {
      node_name    = "pve2"
      vm_id        = 1402
      ipv4_address = "192.168.1.42/24"
    }
  }

  source = "../modules/proxmox/lxc"

  name         = "api-lb-${each.key}"
  node_name    = each.value.node_name
  vm_id        = each.value.vm_id
  ipv4_address = each.value.ipv4_address

  container_template = {
    file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    type    = "debian"
  }

  pve_connection = var.pve_connection
}
```

## Hook Scripts

If `hook_script_content` is provided, the module uploads it as a Proxmox snippet and attaches it to the container.

This is useful for higher-level modules that render a bootstrap or post-start script outside the base LXC module.

## Notes

- Hook scripts require snippet-capable storage such as `local`.
- The Proxmox environment must allow the provider to manage snippet files on the target node.
- The module defaults to a single container by design; composition is preferred over a built-in instances map.
- Configure the `proxmox` provider in the caller, not inside this module, especially when using Terragrunt or wrapping this module from another module.
