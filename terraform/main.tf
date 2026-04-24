provider "proxmox" {
  endpoint  = var.endpoint
  api_token = "terraform@${var.node_name}!provider=${var.api_token}"
  insecure  = true
  ssh {
    agent    = true
    username = "terraform"
  }
}

# module "karate-dmz" {
#   source = "./modules/karate-dmz"

#   api_token = var.api_token
# }

resource "proxmox_virtual_environment_container" "vault_container" {
  description = "Managed by Terraform"

  node_name     = var.node_name
  vm_id         = 200
  tags          = ["terraform_created", "ansible_managed", "vault"]
  unprivileged  = true
  start_on_boot = true

  disk {
    datastore_id = var.datastore_id
    size         = 4
  }

  initialization {
    hostname = "vault"

    ip_config {
      ipv4 {
        address = "192.168.1.50/24"
        gateway = "192.168.1.1"
      }
    }

    dns {
      domain  = "homelab.lan"
      servers = ["192.168.1.2"]
    }

    user_account {
      keys = [
        trimspace(tls_private_key.vault_key.public_key_openssh)
      ]
      password = random_password.vault_password.result
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = proxmox_download_file.debian_13_lxc_img.id
    type             = "debian"
  }
}

resource "tls_private_key" "vault_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_password" "vault_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "proxmox_virtual_environment_vm" "opensense" {
  vm_id       = 400
  node_name   = var.node_name
  description = "Managed by Terraform"
  on_boot     = true

  # should be true if qemu agent is not installed / enabled on the VM
  stop_on_destroy = true

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
    floating  = 2048 # set equal to dedicated to enable ballooning
  }

  cdrom {
    file_id   = proxmox_download_file.opnsense_26_iso.id
    interface = "ide2"
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = 100
  }

  boot_order = ["scsi0", "ide2", "net0"]

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
}
