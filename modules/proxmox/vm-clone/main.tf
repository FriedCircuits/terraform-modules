terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 3.0.1-rc6"
    }
  }
}

resource "null_resource" "cloud_init" {
  triggers = {
    vars = var.cloud_init
  }

  connection {
    type        = "ssh"
    user        = var.pve_connection.ssh_user
    private_key = var.pve_connection.private_key
    host        = var.pve_connection.host
  }

  provisioner "file" {
    content     = var.cloud_init
    destination = "/var/lib/vz/snippets/cloud_init_${var.vm.name}.yml"
  }
}

resource "proxmox_vm_qemu" "vm" {
  name        = var.vm.name
  desc        = var.vm.description
  target_node = var.pve_connection.node
  boot        = var.boot
  agent       = var.agent_enabled
  onboot      = var.onboot
  vm_state    = var.vm_state

  bios = var.specs.bios

  clone      = var.clone
  full_clone = var.full_clone

  dynamic "disk" {
    for_each = var.disks != null ? var.disks : []
    content {
      storage    = disk.value["storage"]
      type       = disk.value["type"]
      format     = disk.value["format"]
      size       = disk.value["size"]
      slot       = disk.value["slot"]
      emulatessd = disk.value["emulatessd"]
      discard    = disk.value["discard"]
      iothread   = disk.value["iothread"]
    }
  }

  cores   = var.specs.cores
  sockets = var.specs.sockets
  memory  = var.specs.memory

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=dhcp"

  cicustom = "user=local:snippets/cloud_init_${var.vm.name}.yml"

  tags = var.tags

  lifecycle {
    # Inherited from template but causes changes on next apply.
    ignore_changes = [
      ciuser,
      sshkeys,
    ]
  }

  depends_on = [
    null_resource.cloud_init
  ]
}
