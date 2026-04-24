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
