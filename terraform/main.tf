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
