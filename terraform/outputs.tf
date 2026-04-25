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
