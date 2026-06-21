###############################################################################
# PVE Containers
###############################################################################

resource "proxmox_virtual_environment_container" "vault_container" {
  description = "Managed by Terraform"

  node_name     = "pve"
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
      domain  = var.dns_domain
      servers = var.dns_servers
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
    template_file_id = proxmox_download_file.debian_13_lxc_img["pve"].id
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

  node_name    = "pve"
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
      domain  = var.dns_domain
      servers = var.dns_servers
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
    template_file_id = proxmox_download_file.debian_13_lxc_img["pve"].id
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

  node_name    = "pve"
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
      domain  = var.dns_domain
      servers = var.dns_servers
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
    template_file_id = proxmox_download_file.debian_13_lxc_img["pve"].id
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

resource "proxmox_virtual_environment_container" "gitea_container" {
  description = "Managed by Terraform"

  node_name     = "pve"
  vm_id         = 203
  tags          = ["terraform_created", "nixos", "gitea"]
  unprivileged  = true
  start_on_boot = true

  disk {
    datastore_id = var.datastore_id
    size         = 20
  }

  memory {
    dedicated = 2048
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "gitea"

    ip_config {
      ipv4 {
        address = "192.168.100.53/24"
        gateway = "192.168.100.1"
      }
      ipv6 {
        address = "fd00:100::53/64"
        gateway = "fd00:100::1"
      }
    }

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    user_account {
      keys = [
        trimspace(tls_private_key.gitea_key.public_key_openssh),
        var.admin_public_key,
      ]
      password = random_password.gitea_password.result
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = proxmox_download_file.nixos_img["pve"].id
    type             = "nixos"
  }
}

resource "tls_private_key" "gitea_key" {
  algorithm = "ED25519"
}

resource "random_password" "gitea_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "proxmox_virtual_environment_container" "homepage_container" {
  description = "Managed by Terraform"

  node_name     = "pve"
  vm_id         = 204
  tags          = ["terraform_created", "nixos", "homepage"]
  unprivileged  = true
  start_on_boot = true

  disk {
    datastore_id = var.datastore_id
    size         = 8
  }

  memory {
    dedicated = 512
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "homepage"

    ip_config {
      ipv4 {
        address = "192.168.100.12/24"
        gateway = "192.168.100.1"
      }
      ipv6 {
        address = "fd00:100::12/64"
        gateway = "fd00:100::1"
      }
    }

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    user_account {
      keys = [
        trimspace(tls_private_key.homepage_key.public_key_openssh),
        var.admin_public_key,
      ]
      password = random_password.homepage_password.result
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = proxmox_download_file.nixos_img["pve"].id
    type             = "nixos"
  }
}

resource "tls_private_key" "homepage_key" {
  algorithm = "ED25519"
}

resource "random_password" "homepage_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

###
# Homepage Proxmox API User
###
resource "proxmox_virtual_environment_user" "homepage" {
  comment = "Homepage Dashboard Monitoring - Managed by Terraform"
  user_id = "homepage@pve"
  enabled = true
}

resource "proxmox_acl" "homepage_readonly" {
  user_id   = proxmox_virtual_environment_user.homepage.user_id
  role_id   = "PVEAuditor"
  path      = "/"
  propagate = true
}

resource "proxmox_user_token" "homepage" {
  comment               = "Homepage Dashboard Token"
  token_name            = "dashboard"
  user_id               = proxmox_virtual_environment_user.homepage.user_id
  privileges_separation = false
}

###############################################################################
# Beelink Containers
###############################################################################

resource "proxmox_virtual_environment_container" "matrix_container" {
  description = "Matrix Synapse - Managed by Terraform"

  node_name     = "beelink"
  vm_id         = 300
  tags          = ["terraform_created", "ansible_managed", "matrix"]
  unprivileged  = true
  start_on_boot = true

  disk {
    datastore_id = var.datastore_id
    size         = 50
  }

  memory {
    dedicated = 4096
  }

  cpu {
    cores = 2
  }

  features {
    nesting = true
  }

  initialization {
    hostname = "matrix"

    ip_config {
      ipv4 {
        address = "192.168.100.13/24"
        gateway = "192.168.100.1"
      }
      ipv6 {
        address = "fd00:100::13/64"
        gateway = "fd00:100::1"
      }
    }

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    user_account {
      keys = [
        trimspace(tls_private_key.matrix_key.public_key_openssh),
        var.admin_public_key,
      ]
      password = random_password.matrix_password.result
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = proxmox_download_file.debian_13_lxc_img["beelink"].id
    type             = "debian"
  }
}

resource "tls_private_key" "matrix_key" {
  algorithm = "ED25519"
}

resource "random_password" "matrix_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}
