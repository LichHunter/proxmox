resource "proxmox_download_file" "debian_12_lxc_img" {
  content_type = "vztmpl"
  datastore_id = var.imagestore_id
  node_name    = var.node_name
  # https://forum.proxmox.com/threads/solved-automating-with-bpg-proxmox-how-to-find-url-and-checksum-of-lxc-images.140315/
  url                = "http://download.proxmox.com/images/system/debian-12-standard_12.12-1_amd64.tar.zst"
  checksum           = "50c85eaaece677a3ebe01cc909b83872e9da2a22c29ae652838afce71e83222fdf40f6accecd7d52b180e912fc1f85ecdf7b3fc4d3027da4d865e509a9e76597"
  checksum_algorithm = "sha512"
  upload_timeout     = 300
}

resource "proxmox_download_file" "debian_13_lxc_img" {
  content_type       = "vztmpl"
  datastore_id       = var.imagestore_id
  node_name          = var.node_name
  url                = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  checksum           = "5aec4ab2ac5c16c7c8ecb87bfeeb10213abe96db6b85e2463585cea492fc861d7c390b3f9c95629bf690b95e9dfe1037207fc69c0912429605f208d5cb2621f8"
  checksum_algorithm = "sha512"
  upload_timeout     = 300
}

resource "proxmox_download_file" "nixos_img" {
  content_type   = "vztmpl"
  datastore_id   = var.imagestore_id
  node_name      = var.node_name
  url            = "https://hydra.nixos.org/build/327796555/download/1/nixos-image-lxc-proxmox-26.05pre-git-x86_64-linux.tar.xz"
  upload_timeout = 300
}
