provider "proxmox" {
  endpoint  = var.endpoint
  api_token = "terraform@pve!provider=${var.api_token}"
  insecure  = true
  ssh {
    agent    = true
    username = "terraform"
  }
}

resource "proxmox_apt_standard_repository" "pve_no_subscription" {
  for_each = toset(var.nodes)
  node     = each.value
  handle   = "no-subscription"
}
