resource "authentik_group" "service_accounts" {
  name = "service-accounts"
}

resource "authentik_group" "opnsense" {
  name  = "opnsense"
  roles = [authentik_rbac_role.ldap_searchers.id]
}

resource "authentik_user" "opnsense" {
  username = "opnsense"
  name     = "opnsense"
  groups = [
    authentik_group.service_accounts.id,
    authentik_group.opnsense.id
  ]
  type     = "service_account"
  password = random_password.opnsense.result
}

resource "random_password" "opnsense" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "authentik_rbac_role" "ldap_searchers" {
  name = "LDAP Search Role"
}

# Assign permission to the role (not individual users)
resource "authentik_rbac_permission_role" "ldap_search" {
  role       = authentik_rbac_role.ldap_searchers.id
  permission = "search_full_directory"
  model      = "authentik_providers_ldap.ldapprovider"
  object_id  = authentik_provider_ldap.ldap.id
}

resource "authentik_rbac_permission_role" "ldap_view" {
  role       = authentik_rbac_role.ldap_searchers.id
  permission = "view_ldapprovider"
  model      = "authentik_providers_ldap.ldapprovider"
  object_id  = authentik_provider_ldap.ldap.id
}

resource "authentik_group" "grafana_admins" {
  name = "Grafana Admins"
}

resource "authentik_group" "grafana_editors" {
  name = "Grafana Editors"
}

resource "authentik_group" "grafana_viewers" {
  name = "Grafana Viewers"
}
