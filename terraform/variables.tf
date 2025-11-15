variable "endpoint" {
  description = "Proxmox address, should look like https://ip_address:port/"
  type        = string
  default     = "https://localhost:8006"
}

variable "username" {
  description = "Proxmox username"
  type        = string
}

variable "password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}
