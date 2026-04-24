variable "endpoint" {
  description = "Proxmox address, should look like https://ip_address:port/"
  type        = string
  default     = "https://localhost:8006"
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "datastore_id" {
  description = "Proxmox storage where LXCs will be stored"
  type        = string
  default     = "local"
}

variable "api_token" {
  description = "Proxmox terraform user api token"
  type        = string
  sensitive   = true
}
