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

output "ansible_hosts" {
  value = {
    containers = {
      vault = {
        hostname = proxmox_virtual_environment_container.vault_container.initialization[0].hostname
        ip       = split("/", proxmox_virtual_environment_container.vault_container.initialization[0].ip_config[0].ipv4[0].address)[0]
        tags     = proxmox_virtual_environment_container.vault_container.tags
        vm_id    = proxmox_virtual_environment_container.vault_container.vm_id
      }
    }
  }
}
