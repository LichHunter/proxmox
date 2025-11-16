provider "proxmox" {
  endpoint = var.endpoint

  username = var.username

  password = var.password

  insecure = true

  ssh {
    agent = true
  }
}

resource "proxmox_virtual_environment_container" "ubuntu_container" {
  description = "Managed by Terraform"

  node_name = "proxmox"
  vm_id     = 1234
  tags      = ["ansible_managed"]

  disk {
    datastore_id = "local"
    size         = 4
  }

  initialization {
    hostname = "CT1234"

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
    template_file_id = proxmox_virtual_environment_download_file.debian_12_lxc_img.id
    # Or you can use a volume ID, as obtained from a "pvesm list <storage>"
    # template_file_id = "local:vztmpl/jammy-server-cloudimg-amd64.tar.gz"
    type = "debian"
  }
}

# resource "proxmox_virtual_environment_download_file" "ubuntu_2410_lxc_img" {
#   content_type = "vztmpl"
#   datastore_id = "local"
#   node_name    = "proxmox"
#   url          = "https://mirrors.servercentral.com/ubuntu-cloud-images/releases/24.10/release/ubuntu-24.10-server-cloudimg-arm64.tar.gz"
# }

resource "proxmox_virtual_environment_download_file" "debian_12_lxc_img" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "proxmox"
  # https://forum.proxmox.com/threads/solved-automating-with-bpg-proxmox-how-to-find-url-and-checksum-of-lxc-images.140315/
  url                = "http://download.proxmox.com/images/system/debian-12-standard_12.2-1_amd64.tar.zst"
  checksum           = "1846c5e64253256832c6f7b8780c5cb241abada3ab0913940b831bf8f7f869220277f5551f0abeb796852e448c178be22bd44eb1af8c0be3d5a13decf943398a"
  checksum_algorithm = "sha512"
  upload_timeout     = 300
}

resource "random_password" "ubuntu_container_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_container_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# resource "proxmox_virtual_environment_apt_standard_repository" "no_subscription_repository" {
#   handle = "no-subscription"
#   node   = "pve"
# }

# resource "proxmox_virtual_environment_apt_repository" "example" {
#   enabled   = true
#   file_path = proxmox_virtual_environment_apt_standard_repository.example.file_path
#   index     = proxmox_virtual_environment_apt_standard_repository.example.index
#   node      = proxmox_virtual_environment_apt_standard_repository.example.node
# }
#
