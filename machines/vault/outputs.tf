output "homepage_role_id" {
  value = vault_approle_auth_backend_role.homepage.role_id
}

output "homepage_secret_id" {
  value     = vault_approle_auth_backend_role_secret_id.homepage.secret_id
  sensitive = true
}
