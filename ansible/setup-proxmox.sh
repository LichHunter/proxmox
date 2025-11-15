#!/usr/bin/env sh

ansible-playbook -i inventory/hosts.yaml playbooks/setup-proxmox-host.yaml

ansible-playbook -i inventory/hosts.yaml playbooks/configure-lxc.yaml
