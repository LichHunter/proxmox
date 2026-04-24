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
  node_name    = var.node_name
  # https://forum.proxmox.com/threads/solved-automating-with-bpg-proxmox-how-to-find-url-and-checksum-of-lxc-images.140315/
  url                = "http://download.proxmox.com/images/system/debian-12-standard_12.12-1_amd64.tar.zst"
  checksum           = "50c85eaaece677a3ebe01cc909b83872e9da2a22c29ae652838afce71e83222fdf40f6accecd7d52b180e912fc1f85ecdf7b3fc4d3027da4d865e509a9e76597"
  checksum_algorithm = "sha512"
  upload_timeout     = 300
}
