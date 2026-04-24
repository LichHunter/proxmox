output "debian_container_password" {
  value     = random_password.debian_container_password.result
  sensitive = true
}

output "debian_container_private_key" {
  value     = tls_private_key.debian_container_key.private_key_pem
  sensitive = true
}

output "debian_container_public_key" {
  value = tls_private_key.debian_container_key.public_key_openssh
}

output "container_id" {
  value = proxmox_virtual_environment_container.mongodb_container.vm_id
}

output "gitlab_vm_password" {
  value     = random_password.gitlab_vm_password.result
  sensitive = true
}

output "gitlab_vm_private_key" {
  value     = tls_private_key.gitlab_vm_key.private_key_pem
  sensitive = true
}

output "gitlab_vm_public_key" {
  value = tls_private_key.gitlab_vm_key.public_key_openssh
}

output "gitlab_vm_hostname" {
  value = "gitlab"
}

output "gitlab_vm_id" {
  value = proxmox_virtual_environment_vm.gitlab_vm.vm_id
}
