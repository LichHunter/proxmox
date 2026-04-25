# LDAP Flow
resource "authentik_stage_identification" "ldap" {
  name           = "ldap-identification-stage"
  user_fields    = ["username", "email"]
  password_stage = authentik_stage_password.ldap.id
}

resource "authentik_stage_password" "ldap" {
  name = "ldap-authentication-password"
  backends = [
    "authentik.core.auth.InbuiltBackend",
    "authentik.sources.ldap.auth.LDAPBackend",
    "authentik.core.auth.TokenBackend"
  ]
}

resource "authentik_stage_user_login" "ldap" {
  name             = "ldap-authentication-login"
  session_duration = "seconds=0"
}

resource "authentik_stage_user_logout" "logout" {
  name = "ldap-logout"
}

resource "authentik_flow" "ldap_bind" {
  name        = "ldap-authentication-flow"
  title       = "ldap-authentication-flow"
  slug        = "ldap-authentication-flow"
  designation = "authentication"
}

resource "authentik_flow_stage_binding" "ldap_indentification" {
  target = authentik_flow.ldap_bind.uuid
  stage  = authentik_stage_identification.ldap.id
  order  = 10
}

resource "authentik_flow_stage_binding" "ldap_login" {
  target = authentik_flow.ldap_bind.uuid
  stage  = authentik_stage_user_login.ldap.id
  order  = 30
}

resource "authentik_flow" "ldap_unbind" {
  name        = "Custom LDAP Unbind"
  slug        = "custom-ldap-unbind"
  title       = "Custom LDAP Unbind"
  designation = "invalidation"
}

resource "authentik_flow_stage_binding" "unbind_1_logout" {
  target = authentik_flow.ldap_unbind.uuid
  stage  = authentik_stage_user_logout.logout.id
  order  = 10
}

#-------

# Custom Authentication Flow (based on default flow structure)
resource "authentik_flow" "custom_authentication" {
  name        = "Custom Authentication Flow"
  title       = "Welcome to authentik!"
  slug        = "custom-authentication-flow"
  designation = "authentication"
}

resource "authentik_stage_identification" "custom_authentication" {
  name              = "custom-identification-stage"
  user_fields       = ["username", "email"]
  sources           = []
  passwordless_flow = authentik_flow.passkey_authentication.uuid
}

data "authentik_stage" "default_authentication_password" {
  name = "default-authentication-password"
}

data "authentik_stage" "default_authentication_mfa_validation" {
  name = "default-authentication-mfa-validation"
}

data "authentik_stage" "default_authentication_login" {
  name = "default-authentication-login"
}

resource "authentik_flow_stage_binding" "custom_identification" {
  target = authentik_flow.custom_authentication.uuid
  stage  = authentik_stage_identification.custom_authentication.id
  order  = 10
}

resource "authentik_flow_stage_binding" "custom_password" {
  target = authentik_flow.custom_authentication.uuid
  stage  = data.authentik_stage.default_authentication_password.id
  order  = 20
}

resource "authentik_flow_stage_binding" "custom_mfa" {
  target = authentik_flow.custom_authentication.uuid
  stage  = data.authentik_stage.default_authentication_mfa_validation.id
  order  = 30
}

resource "authentik_flow_stage_binding" "custom_login" {
  target = authentik_flow.custom_authentication.uuid
  stage  = data.authentik_stage.default_authentication_login.id
  order  = 100
}

#-------

# Custom Local Authentication Flow
resource "authentik_flow" "custom_local_authentication" {
  name        = "Custom Local Authentication Flow"
  title       = "Welcome to authentik!"
  slug        = "custom-local-authentication-flow"
  designation = "authentication"
}

data "authentik_stage" "default_authentication_identification" {
  name = "default-authentication-identification"
}

resource "authentik_flow_stage_binding" "custom_local_identification" {
  target = authentik_flow.custom_local_authentication.uuid
  stage  = data.authentik_stage.default_authentication_identification.id
  order  = 10
}

resource "authentik_flow_stage_binding" "custom_local_password" {
  target = authentik_flow.custom_local_authentication.uuid
  stage  = data.authentik_stage.default_authentication_password.id
  order  = 20
}

resource "authentik_flow_stage_binding" "custom_local_login" {
  target = authentik_flow.custom_local_authentication.uuid
  stage  = data.authentik_stage.default_authentication_login.id
  order  = 100
}

#--------

# Passkey Authentication Flow

resource "authentik_flow" "passkey_authentication" {
  name        = "Passkey Authentication Flow"
  title       = "Welcome! Please authenticate with your passkey"
  slug        = "passkey-authentication-flow"
  designation = "authentication"
}

resource "authentik_stage_authenticator_webauthn" "passkey_setup" {
  name                     = "passkey-webauthn-setup"
  user_verification        = "required"
  authenticator_attachment = "platform"
}

resource "authentik_stage_authenticator_validate" "passkey_validate" {
  name                       = "passkey-validate-stage"
  device_classes             = ["webauthn"]
  not_configured_action      = "configure"
  configuration_stages       = [authentik_stage_authenticator_webauthn.passkey_setup.id]
  webauthn_user_verification = "required"
}

resource "authentik_stage_user_login" "passkey" {
  name             = "passkey-authentication-login"
  session_duration = "seconds=0"
}

resource "authentik_flow_stage_binding" "passkey_validation" {
  target = authentik_flow.passkey_authentication.uuid
  stage  = authentik_stage_authenticator_validate.passkey_validate.id
  order  = 10
}

resource "authentik_flow_stage_binding" "passkey_login" {
  target = authentik_flow.passkey_authentication.uuid
  stage  = authentik_stage_user_login.passkey.id
  order  = 20
}
#---------

data "authentik_flow" "default_provider_authorization_implicit_consent" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default_provider_invalidation_flow" {
  slug = "default-provider-invalidation-flow"
}
