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

resource "proxmox_download_file" "opnsense_26_iso" {
  content_type            = "iso"
  datastore_id            = var.imagestore_id
  node_name               = var.node_name
  file_name               = "OPNsense-26.1.6-vga-amd64.iso"
  url                     = "https://pkg.opnsense.org/releases/26.1.6/OPNsense-26.1.6-dvd-amd64.iso.bz2"
  checksum                = "9054d9c0c18b3c1a1fd29f4cacef2c522a91f2e5f803c64b9b738000ee0eab2f2e194f8daa9a2d30c73af6ef8557739b443b2f1dea5d0651469aae54979d0757"
  checksum_algorithm      = "sha512"
  decompression_algorithm = "bz2"
  upload_timeout          = 300
  overwrite               = false
}
