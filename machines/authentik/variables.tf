variable "token" {
  description = "Authentik Terraform Token"
  type        = string
  sensitive   = true
}

variable "authentik_ip" {
  description = "Authentik server IP address"
  type        = string
}
