variable "endpoint" {
  description = "Proxmox address, should look like https://ip_address:port/"
  type        = string
  default     = "https://localhost:8006"
}

variable "nodes" {
  description = "List of Proxmox node names to manage"
  type        = list(string)
  default     = ["pve"]
}

variable "imagestore_id" {
  description = "Proxmox storate where Templates and ISOs will be stored"
  type        = string
  default     = "local"
}

variable "datastore_id" {
  description = "Proxmox storage where LXCs will be stored"
  type        = string
  default     = "local-lvm"
}

variable "api_token" {
  description = "Proxmox terraform user api token"
  type        = string
  sensitive   = true
}

variable "admin_public_key" {
  description = "Admin SSH public key added to managed containers"
  type        = string
}

variable "dns_domain" {
  description = "DNS search domain for containers"
  type        = string
  default     = "homelab.lan"
}

variable "dns_servers" {
  description = "DNS servers for containers"
  type        = list(string)
  default     = ["192.168.100.1"]
}
