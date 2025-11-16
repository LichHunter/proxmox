#! /usr/bin/env nix
#! nix shell nixpkgs#ansible --command bash

ansible-playbook -i inventory/hosts.dev.yaml playbooks/setup-proxmox-host.yaml

ansible-playbook -i inventory/hosts.dev.yaml playbooks/configure-lxc.yaml --extra-vars "@vars/dev.yaml"
