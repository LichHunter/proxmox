# Grafana
resource "authentik_provider_oauth2" "grafana" {
  name               = "Grafana"
  client_id          = random_password.grafana_id.result
  client_secret      = random_password.grafana_secret.result
  authorization_flow = data.authentik_flow.default_provider_authorization_implicit_consent.id
  invalidation_flow  = data.authentik_flow.default_provider_invalidation_flow.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "https://grafana.homelab.com/login/generic_oauth",
    }
  ]
  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
  ]
  signing_key   = data.authentik_certificate_key_pair.homelab.id
  logout_method = "frontchannel"
  logout_uri    = "https://grafana.homelab.com/logout"
}

resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id
}

resource "random_password" "grafana_id" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "random_password" "grafana_secret" {
  length           = 32
  override_special = "_%@"
  special          = true
}

data "authentik_property_mapping_provider_scope" "scope-email" {
  name = "authentik default OAuth Mapping: OpenID 'email'"
}

data "authentik_property_mapping_provider_scope" "scope-profile" {
  name = "authentik default OAuth Mapping: OpenID 'profile'"
}

data "authentik_property_mapping_provider_scope" "scope-openid" {
  name = "authentik default OAuth Mapping: OpenID 'openid'"
}

# ------

# GitLab
resource "authentik_provider_oauth2" "gitlab" {
  name               = "GitLab"
  client_id          = random_password.gitlab_id.result
  client_secret      = random_password.gitlab_secret.result
  authorization_flow = data.authentik_flow.default_provider_authorization_implicit_consent.id
  invalidation_flow  = data.authentik_flow.default_provider_invalidation_flow.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "https://gitlab.homelab.com/users/auth/openid_connect/callback",
    }
  ]
  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
  ]
  signing_key = data.authentik_certificate_key_pair.homelab.id

  sub_mode                   = "user_email"
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"
}

resource "authentik_application" "gitlab" {
  name              = "GitLab"
  slug              = "gitlab"
  protocol_provider = authentik_provider_oauth2.gitlab.id
}

resource "random_password" "gitlab_id" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "random_password" "gitlab_secret" {
  length           = 32
  override_special = "_%@"
  special          = true
}
