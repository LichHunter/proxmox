resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_approle_auth_backend_role" "vault" {
  backend        = vault_auth_backend.approle.path
  role_name      = "vault"
  token_ttl      = 3600
  token_max_ttl  = 86400
  token_policies = [vault_policy.issue_homelab_certs.name]
}

resource "vault_approle_auth_backend_role" "authentik" {
  backend        = vault_auth_backend.approle.path
  role_name      = "authentik"
  token_ttl      = 3600
  token_max_ttl  = 86400
  token_policies = [vault_policy.issue_homelab_certs.name]
}

resource "vault_approle_auth_backend_role" "nixarr" {
  backend        = vault_auth_backend.approle.path
  role_name      = "nixarr"
  token_ttl      = 3600
  token_max_ttl  = 86400
  token_policies = [vault_policy.issue_homelab_certs.name]
}

resource "vault_approle_auth_backend_role" "gitea" {
  backend        = vault_auth_backend.approle.path
  role_name      = "gitea"
  token_ttl      = 3600
  token_max_ttl  = 86400
  token_policies = [vault_policy.issue_homelab_certs.name]
}


resource "vault_approle_auth_backend_role" "homepage" {
  backend        = vault_auth_backend.approle.path
  role_name      = "homepage"
  token_ttl      = 3600
  token_max_ttl  = 86400
  token_policies = [vault_policy.issue_homelab_certs.name]
}

resource "vault_approle_auth_backend_role_secret_id" "homepage" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.homepage.role_name
}
