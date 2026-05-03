###
# Containers
###
resource "proxmox_virtual_environment_container" "vault_container" {
  description = "Managed by Terraform"

  node_name     = var.node_name
  vm_id         = 200
  tags          = ["terraform_created", "ansible_managed", "vault"]
  unprivileged  = true
  start_on_boot = true

  disk {
    datastore_id = var.datastore_id
    size         = 10
  }

  memory {
    dedicated = 2048
  }

  initialization {
    hostname = "vault"

    ip_config {
      ipv4 {
        address = "192.168.100.50/24"
        gateway = "192.168.100.1"
      }
      ipv6 {
        address = "fd00:100::50/64"
        gateway = "fd00:100::1"
      }
    }

    dns {
      domain  = "homelab.lan"
      servers = ["192.168.100.1"]
    }

    user_account {
      keys = [
        trimspace(tls_private_key.vault_key.public_key_openssh)
      ]
      password = random_password.vault_password.result
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = proxmox_download_file.debian_13_lxc_img.id
    type             = "debian"
  }
}

resource "tls_private_key" "vault_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_password" "vault_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "proxmox_virtual_environment_container" "root_ca_container" {
  description = "Managed by Terraform"

  node_name    = var.node_name
  vm_id        = 201
  tags         = ["terraform_created", "ansible_managed", "root_ca"]
  unprivileged = true

  disk {
    datastore_id = var.datastore_id
    size         = 4
  }

  memory {
    dedicated = 256
  }

  initialization {
    hostname = "root-ca"

    ip_config {
      ipv4 {
        address = "192.168.100.51/24"
        gateway = "192.168.100.1"
      }
      ipv6 {
        address = "fd00:100::51/64"
        gateway = "fd00:100::1"
      }
    }

    dns {
      domain  = "homelab.lan"
      servers = ["192.168.100.1"]
    }

    user_account {
      keys = [
        trimspace(tls_private_key.root_ca_key.public_key_openssh)
      ]
      password = random_password.root_ca_password.result
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = proxmox_download_file.debian_13_lxc_img.id
    type             = "debian"
  }
}

resource "tls_private_key" "root_ca_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_password" "root_ca_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "proxmox_virtual_environment_container" "authentik_container" {
  description = "Managed by Terraform"

  node_name    = var.node_name
  vm_id        = 202
  tags         = ["terraform_created", "ansible_managed", "authentik"]
  unprivileged = true

  disk {
    datastore_id = var.datastore_id
    size         = 20
  }

  memory {
    dedicated = 4096
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "authentik"

    ip_config {
      ipv4 {
        address = "192.168.100.52/24"
        gateway = "192.168.100.1"
      }
      ipv6 {
        address = "fd00:100::52/64"
        gateway = "fd00:100::1"
      }
    }

    dns {
      domain  = "homelab.lan"
      servers = ["192.168.100.1"]
    }

    user_account {
      keys = [
        trimspace(tls_private_key.authentik_key.public_key_openssh)
      ]
      password = random_password.authentik_password.result
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = proxmox_download_file.debian_13_lxc_img.id
    type             = "debian"
  }
}

resource "tls_private_key" "authentik_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_password" "authentik_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

# resource "proxmox_virtual_environment_container" "nixarr_container" {
#   description = "Managed by Terraform"

#   node_name    = var.node_name
#   vm_id        = 203
#   tags         = ["terraform_created", "nixos", "nixarr"]
#   unprivileged = true

#   disk {
#     datastore_id = var.datastore_id
#     size         = 50
#   }

#   # TODO requires the machine to be recreated for some reason
#   # cpu {
#   #   cores = 4
#   # }

#   memory {
#     dedicated = 4096 # should be updated to 8192
#   }

#   features {
#     nesting = true
#   }

#   mount_point {
#     volume = "media"
#     size   = "800G"
#     path   = "/media"
#   }

#   initialization {
#     hostname = "nixarr"

#     ip_config {
#       ipv4 {
#         address = "192.168.1.54/24"
#         gateway = "192.168.1.1"
#       }
#     }

#     dns {
#       domain  = "homelab.lan"
#       servers = ["192.168.1.2"]
#     }

#     user_account {
#       keys = [
#         trimspace(tls_private_key.nixarr_key.public_key_openssh),
#         var.admin_public_key,
#       ]
#       password = random_password.nixarr_password.result
#     }
#   }

#   network_interface {
#     name   = "eth0"
#     bridge = "vmbr0"
#   }

#   operating_system {
#     template_file_id = proxmox_virtual_environment_file.nixos_img.id
#     type             = "nixos"
#   }
# }

# resource "tls_private_key" "nixarr_key" {
#   algorithm = "ED25519"
# }

# resource "random_password" "nixarr_password" {
#   length           = 16
#   override_special = "_%@"
#   special          = true
# }
