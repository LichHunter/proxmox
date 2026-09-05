variable "opnsense_uri" {
  description = "OPNsense API endpoint, e.g. https://192.168.100.1"
  type        = string
}

variable "opnsense_api_key" {
  description = "API key of the dedicated terraform user (System > Access > Users > API keys)"
  type        = string
  sensitive   = true
}

variable "opnsense_api_secret" {
  description = "API secret of the dedicated terraform user"
  type        = string
  sensitive   = true
}
