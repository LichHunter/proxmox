locals {
  vault_addr         = "https://vault.homelab.lan:8200"
  intermediate_mount = "intermediate_ca"
}

resource "vault_pki_secret_backend_config_cluster" "intermediate" {
  backend  = local.intermediate_mount
  path     = "${local.vault_addr}/v1/${local.intermediate_mount}"
  aia_path = "${local.vault_addr}/v1/${local.intermediate_mount}"
}

resource "vault_pki_secret_backend_config_urls" "intermediate" {
  backend                 = local.intermediate_mount
  issuing_certificates    = ["${local.vault_addr}/v1/${local.intermediate_mount}/der"]
  crl_distribution_points = ["${local.vault_addr}/v1/${local.intermediate_mount}/crl/der"]
  ocsp_servers            = ["${local.vault_addr}/v1/${local.intermediate_mount}/ocsp"]
  enable_templating       = true
}

resource "vault_pki_secret_backend_config_acme" "intermediate" {
  backend                  = local.intermediate_mount
  enabled                  = true
  allowed_issuers          = ["default"]
  allowed_roles            = [vault_pki_secret_backend_role.intermediate_role.name]
  allow_role_ext_key_usage = false
  default_directory_policy = "role:${vault_pki_secret_backend_role.intermediate_role.name}"
  dns_resolver             = "192.168.1.2:53"
  eab_policy               = "not-required"
}

resource "vault_pki_secret_backend_role" "intermediate_role" {
  backend           = local.intermediate_mount
  issuer_ref        = "default"
  name              = "issue-homelab-certs"
  ttl               = 86400
  max_ttl           = 2592000
  allow_ip_sans     = true
  key_type          = "rsa"
  key_bits          = 4096
  allowed_domains   = ["homelab.lan"]
  allow_subdomains  = true
  allow_localhost   = true
  enforce_hostnames = true

  organization = ["Homelab"]
  country      = ["NL"]
}

resource "vault_pki_secret_backend_config_auto_tidy" "intermediate" {
  backend            = local.intermediate_mount
  enabled            = true
  interval_duration  = "24h"
  tidy_cert_store    = true
  tidy_revoked_certs = true
  safety_buffer      = "72h"
}
