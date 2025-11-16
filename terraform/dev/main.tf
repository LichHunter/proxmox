provider "proxmox" {
  endpoint  = var.endpoint
  api_token = "terraform@pve!provider=${var.api_token}"
  insecure  = true
  ssh {
    agent    = true
    username = "terraform"
  }
}

resource "proxmox_virtual_environment_container" "mongodb_container" {
  description = "Managed by Terraform"

  node_name    = var.node_name
  vm_id        = 1235
  tags         = ["ansible_managed", "mongodb"]
  unprivileged = true

  disk {
    datastore_id = var.datastore_id
    size         = 4
  }

  initialization {
    hostname = "mongodb"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr1"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.debian_13_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type = "debian"
  }
}

resource "proxmox_virtual_environment_container" "vault_container" {
  description = "Managed by Terraform"

  node_name    = var.node_name
  vm_id        = 1236
  tags         = ["ansible_managed", "vault"]
  unprivileged = true

  disk {
    datastore_id = var.datastore_id
    size         = 4
  }

  initialization {
    hostname = "vault"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr1"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.debian_13_lxc_img.id
    type             = "debian"
  }
}

resource "proxmox_virtual_environment_vm" "opnsense_vm" {
  vm_id       = 1237
  name        = "firewall"
  node_name   = var.node_name
  description = "Managed by Terraform"
  on_boot     = true

  # should be true if qemu agent is not installed / enabled on the VM
  stop_on_destroy = true

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = false
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
    floating  = 2048 # set equal to dedicated to enable ballooning
  }

  cdrom {
    file_id   = proxmox_virtual_environment_download_file.opnsense_iso.id
    interface = "ide2"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 32
  }

  boot_order = ["scsi0", "ide2", "net0"]

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }
}

# Jumpbox machine to allow ssh connection inside firewall
resource "proxmox_virtual_environment_container" "jumpbox_container" {
  description = "Managed by Terraform"

  node_name    = var.node_name
  vm_id        = 1238
  tags         = ["ansible_managed", "jumpbox"]
  unprivileged = true

  disk {
    datastore_id = var.datastore_id
    size         = 4
  }

  initialization {
    hostname = "jumpbox"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  network_interface {
    name   = "eth1"
    bridge = "vmbr1"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.debian_13_lxc_img.id
    type             = "debian"
  }
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr1" {
  node_name = var.node_name
  name      = "vmbr1"
  comment   = "Terraform managed firewall bridge"

  ports = [
  ]
}

resource "proxmox_virtual_environment_download_file" "opnsense_iso" {
  content_type            = "iso"
  datastore_id            = var.datastore_id
  node_name               = var.node_name
  url                     = "https://pkg.opnsense.org/releases/25.7/OPNsense-25.7-dvd-amd64.iso.bz2"
  checksum                = "fa4b30df3f5fd7a2b1a1b2bdfaecfe02337ee42f77e2d0ae8a60753ea7eb153e"
  checksum_algorithm      = "sha256"
  file_name               = "OPNsense-25.7-dvd-amd64.iso"
  decompression_algorithm = "bz2"
}

resource "proxmox_virtual_environment_download_file" "debian_12_lxc_img" {
  content_type = "vztmpl"
  datastore_id = var.datastore_id
  node_name    = var.node_name
  # https://forum.proxmox.com/threads/solved-automating-with-bpg-proxmox-how-to-find-url-and-checksum-of-lxc-images.140315/
  url                = "http://download.proxmox.com/images/system/debian-12-standard_12.2-1_amd64.tar.zst"
  checksum           = "1846c5e64253256832c6f7b8780c5cb241abada3ab0913940b831bf8f7f869220277f5551f0abeb796852e448c178be22bd44eb1af8c0be3d5a13decf943398a"
  checksum_algorithm = "sha512"
  upload_timeout     = 300
}

resource "proxmox_virtual_environment_download_file" "debian_13_lxc_img" {
  content_type       = "vztmpl"
  datastore_id       = var.datastore_id
  node_name          = var.node_name
  url                = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  checksum           = "5aec4ab2ac5c16c7c8ecb87bfeeb10213abe96db6b85e2463585cea492fc861d7c390b3f9c95629bf690b95e9dfe1037207fc69c0912429605f208d5cb2621f8"
  checksum_algorithm = "sha512"
  upload_timeout     = 300
}

resource "random_password" "debian_container_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "debian_container_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
