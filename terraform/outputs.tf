output "vault_private_key" {
  value     = tls_private_key.vault_key.private_key_pem
  sensitive = true
}

output "vault_public_key" {
  value = tls_private_key.vault_key.public_key_openssh
}

output "vault_password" {
  value     = random_password.vault_password.result
  sensitive = true
}
