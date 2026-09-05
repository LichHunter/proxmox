# Global Unbound DNS resolver settings.
#
# Singleton resource: manages already-existing upstream configuration.
# It cannot be created via `tofu apply` (imported below) and `tofu destroy`
# only removes it from state - it never resets the firewall.
#
# Only non-default values are pinned here; omitted attributes keep the
# upstream defaults (verified against the live config on 26.1.6):
#   - DNSSEC validation enabled
#   - local zone type "transparent" for the system domain
#   - port 53, aggressive NSEC (RFC8198), ACL default action "allow",
#     forwarding disabled, no DNSBL
import {
  to = opnsense_unbound_settings.settings
  id = "unbound_settings"
}

resource "opnsense_unbound_settings" "settings" {
  general = {
    enabled         = true
    port            = 53
    enable_dnssec   = true
    local_zone_type = "transparent"
  }
}

# --- Host overrides (existing records, imported by UUID) ---

import {
  to = opnsense_unbound_host_override.vault
  id = "07a3fec3-f797-44b5-9596-43f2979ac901"
}

resource "opnsense_unbound_host_override" "vault" {
  hostname    = "vault"
  domain      = "homelab.lan"
  server      = "192.168.100.50"
  description = "Vault"
}

import {
  to = opnsense_unbound_host_override.firewall
  id = "42374e36-eb5c-4c0a-b13b-ed5999103fef"
}

resource "opnsense_unbound_host_override" "firewall" {
  hostname    = "firewall"
  domain      = "homelab.lan"
  server      = "192.168.100.1"
  description = "Firewall"
}

import {
  to = opnsense_unbound_host_override.proxmox
  id = "c7934662-230f-4047-928e-4b6fc9434b1e"
}

resource "opnsense_unbound_host_override" "proxmox" {
  hostname    = "proxmox"
  domain      = "homelab.lan"
  server      = "192.168.100.10"
  description = "Proxmox"
}

import {
  to = opnsense_unbound_host_override.homepage
  id = "55901261-eedc-44fb-ae1e-967e0e985512"
}

resource "opnsense_unbound_host_override" "homepage" {
  hostname = "homepage"
  domain   = "homelab.lan"
  server   = "192.168.100.12"
}

import {
  to = opnsense_unbound_host_override.matrix
  id = "4db5f035-e720-4078-9965-a3585413935a"
}

resource "opnsense_unbound_host_override" "matrix" {
  hostname = "matrix"
  domain   = "homelab.lan"
  server   = "192.168.100.13"
}

import {
  to = opnsense_unbound_host_override.element
  id = "00a3ff40-355c-4627-a3ec-793818c372a1"
}

resource "opnsense_unbound_host_override" "element" {
  hostname = "element"
  domain   = "homelab.lan"
  server   = "192.168.100.13"
}

import {
  to = opnsense_unbound_host_override.authentik
  id = "0af9f3a1-f26d-4071-915b-b16eff58bf9d"
}

resource "opnsense_unbound_host_override" "authentik" {
  hostname = "authentik"
  domain   = "homelab.lan"
  server   = "192.168.100.52"
}

import {
  to = opnsense_unbound_host_override.auth
  id = "439de1ed-360c-468d-a6da-868e4318d696"
}

resource "opnsense_unbound_host_override" "auth" {
  hostname = "auth"
  domain   = "homelab.lan"
  server   = "192.168.100.13"
}

# --- Query forwarding ---

# The "homelab" zone is served by the local dnsmasq instance (DHCP
# registrations) listening on 127.0.0.1:53053.
import {
  to = opnsense_unbound_forward.homelab_dnsmasq
  id = "f9fdf787-a6ca-481f-af52-fdf16314d254"
}

resource "opnsense_unbound_forward" "homelab_dnsmasq" {
  domain      = "homelab"
  server_ip   = "127.0.0.1"
  server_port = 53053
}
