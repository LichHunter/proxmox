output "vault_private_key" {
  value     = tls_private_key.vault_key.private_key_pem
  sensitive = true
}

output "vault_public_key" {
  value = tls_private_key.vault_key.public_key_openssh
}

output "vault_password" {
  value     = random_password.root_ca_password.result
  sensitive = true
}

output "root_ca_private_key" {
  value     = tls_private_key.root_ca_key.private_key_pem
  sensitive = true
}

output "root_ca_public_key" {
  value = tls_private_key.root_ca_key.public_key_openssh
}

output "root_ca_password" {
  value     = random_password.root_ca_password.result
  sensitive = true
}

output "authentik_private_key" {
  value     = tls_private_key.authentik_key.private_key_pem
  sensitive = true
}

output "authentik_public_key" {
  value = tls_private_key.authentik_key.public_key_openssh
}

output "authentik_password" {
  value     = random_password.authentik_password.result
  sensitive = true
}

output "gitea_private_key" {
  value     = tls_private_key.gitea_key.private_key_openssh
  sensitive = true
}

output "gitea_public_key" {
  value = tls_private_key.gitea_key.public_key_openssh
}

output "gitea_password" {
  value     = random_password.gitea_password.result
  sensitive = true
}

output "homepage_private_key" {
  value     = tls_private_key.homepage_key.private_key_openssh
  sensitive = true
}

output "homepage_public_key" {
  value = tls_private_key.homepage_key.public_key_openssh
}

output "homepage_password" {
  value     = random_password.homepage_password.result
  sensitive = true
}

output "homepage_proxmox_token_id" {
  value = proxmox_user_token.homepage.id
}

output "homepage_proxmox_token_secret" {
  value     = split("=", proxmox_user_token.homepage.value)[1]
  sensitive = true
}

output "matrix_private_key" {
  value     = tls_private_key.matrix_key.private_key_openssh
  sensitive = true
}

output "matrix_public_key" {
  value = tls_private_key.matrix_key.public_key_openssh
}

output "matrix_password" {
  value     = random_password.matrix_password.result
  sensitive = true
}
