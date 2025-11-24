terraform {
  required_version = "~> 1.10"

  backend "http" {
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.86.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}
