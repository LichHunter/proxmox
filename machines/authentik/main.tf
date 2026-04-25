provider "authentik" {
  url      = "https://authentik.homelab.lan:9443"
  token    = var.token
  insecure = true
}

data "authentik_certificate_key_pair" "homelab" {
  name = "authentik.homelab.lan"
}

resource "authentik_provider_ldap" "ldap" {
  depends_on  = [authentik_flow.ldap_bind, authentik_flow.ldap_unbind]
  name        = "LDAP"
  base_dn     = "dc=ldap,dc=goauthentik,dc=io"
  bind_flow   = authentik_flow.ldap_bind.uuid
  unbind_flow = authentik_flow.ldap_unbind.uuid
  certificate = data.authentik_certificate_key_pair.homelab.id
}

resource "authentik_application" "ldap" {
  name              = "ldap"
  slug              = "ldap"
  protocol_provider = authentik_provider_ldap.ldap.id
}

resource "authentik_service_connection_docker" "local" {
  name  = "local"
  local = true
}

resource "authentik_outpost" "ldap" {
  name = "LDAP"
  type = "ldap"
  protocol_providers = [
    authentik_provider_ldap.ldap.id
  ]

  service_connection = authentik_service_connection_docker.local.id

  # As we have docker and ldap outpost on the same machine we can simplify network routing
  config = jsonencode({
    authentik_host          = "http://server:9000"
    authentik_host_insecure = true
    authentik_host_browser  = "https://authentik.homelab.com:9443"
    log_level               = "debug"
    docker_network          = "authentik_default"
  })
}

resource "authentik_policy_binding" "ldap_access_for_service_accounts" {
  target  = authentik_application.ldap.uuid
  group   = authentik_group.service_accounts.id
  order   = 0
  enabled = true
}

resource "authentik_policy_binding" "ldap_access_for_opnsense" {
  target  = authentik_application.ldap.uuid
  group   = authentik_group.opnsense.id
  order   = 10
  enabled = true
}

resource "authentik_brand" "internal" {
  domain              = "authentik.homelab.lan"
  branding_title      = "authentik"
  branding_logo       = "/static/dist/assets/icons/icon_left_brand.svg"
  branding_favicon    = "/static/dist/assets/icons/icon.png"
  flow_authentication = authentik_flow.custom_local_authentication.uuid
  web_certificate     = data.authentik_certificate_key_pair.homelab.id
  default             = true
}

resource "authentik_brand" "external" {
  domain              = "authentik.homelab.com"
  branding_title      = "authentik"
  branding_logo       = "/static/dist/assets/icons/icon_left_brand.svg"
  branding_favicon    = "/static/dist/assets/icons/icon.png"
  flow_authentication = authentik_flow.custom_authentication.uuid
  web_certificate     = data.authentik_certificate_key_pair.homelab.id
}
