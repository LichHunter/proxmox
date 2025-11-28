# Vault Agent Role

This Ansible role installs and configures HashiCorp Vault Agent for automated certificate management using Vault's PKI secrets engine.

## Overview

The role:
- Installs HashiCorp Vault binary
- Configures Vault Agent with AppRole authentication
- Sets up automated certificate renewal using Vault Agent templates
- Creates a systemd service to run Vault Agent continuously
- Automatically reloads services when certificates are renewed

## Requirements

- A running Vault server with PKI secrets engine configured
- AppRole authentication method enabled in Vault
- Role ID and Secret ID for AppRole authentication
- Network connectivity to the Vault server

## Role Variables

### Required Variables

```yaml
vault_agent_role_id: ""       # AppRole Role ID
vault_agent_secret_id: ""     # AppRole Secret ID
```

### Optional Variables (with defaults)

```yaml
# Vault server configuration
vault_agent_vault_addr: "https://192.168.100.20:8200"
vault_agent_approle_mount_path: "auth/approle"

# PKI configuration
vault_agent_pki_role_path: "pki/issue/issue-homelab-certs"
vault_agent_common_name: "nginx.homelab.com"
vault_agent_cert_ttl: "24h"

# Certificate output paths
vault_agent_cert_dest: "/etc/nginx/ssl/nginx.homelab.com.crt"
vault_agent_key_dest: "/etc/nginx/ssl/nginx.homelab.com.key"
vault_agent_cert_perms: "0644"
vault_agent_key_perms: "0600"

# Service reload command
vault_agent_reload_cmd: "systemctl reload nginx"

# Vault Agent paths
vault_agent_config_dir: "/etc/vault"
vault_agent_template_dir: "/etc/vault/templates"
vault_agent_pid_file: "/var/run/vault-agent.pid"
vault_agent_token_sink_path: "/tmp/vault-token"

# Installation
vault_agent_version: "1.18.3"
vault_agent_arch: "amd64"
vault_agent_binary_path: "/usr/local/bin/vault"

# Service user
vault_agent_service_user: "root"
vault_agent_service_group: "root"
```

## Dependencies

None

## Example Playbook

```yaml
---
- name: Configure Vault Agent for Nginx
  hosts: nginx_servers
  become: true
  vars:
    vault_agent_role_id: "{{ vault.nginx_role_id }}"
    vault_agent_secret_id: "{{ vault.nginx_secret_id }}"
    vault_agent_common_name: "nginx.homelab.com"
    vault_agent_cert_dest: "/etc/nginx/ssl/nginx.homelab.com.crt"
    vault_agent_key_dest: "/etc/nginx/ssl/nginx.homelab.com.key"
    vault_agent_reload_cmd: "systemctl reload nginx"
  roles:
    - vault_agent
```

## Example with Multiple Services

You can use this role multiple times for different services by using different common names:

```yaml
---
- name: Configure Vault Agent for multiple services
  hosts: app_servers
  become: true
  tasks:
    # Configure Vault Agent for Nginx
    - name: Setup Vault Agent for Nginx
      include_role:
        name: vault_agent
      vars:
        vault_agent_role_id: "{{ vault.nginx_role_id }}"
        vault_agent_secret_id: "{{ vault.nginx_secret_id }}"
        vault_agent_common_name: "nginx.homelab.com"
        vault_agent_cert_dest: "/etc/nginx/ssl/nginx.homelab.com.crt"
        vault_agent_key_dest: "/etc/nginx/ssl/nginx.homelab.com.key"
        vault_agent_reload_cmd: "systemctl reload nginx"
```

## How It Works

1. **Installation**: Downloads and installs the Vault binary
2. **Configuration**: Creates `/etc/vault/agent.hcl` with AppRole authentication
3. **Templates**: Deploys certificate and key templates to `/etc/vault/templates/`
4. **AppRole Credentials**: Securely stores role_id and secret_id in `/etc/vault/`
5. **Service**: Creates and enables a systemd service for continuous operation
6. **Auto-Renewal**: Vault Agent automatically renews certificates and reloads the service

## Certificate Renewal

Vault Agent continuously monitors certificate expiration and automatically:
- Requests new certificates from Vault before expiration
- Writes the new certificate and key to the configured paths
- Executes the reload command to apply the new certificates

## Security Considerations

- AppRole credentials are stored with 0600 permissions
- Private keys are written with 0600 permissions (configurable)
- The service runs as root by default (can be changed via `vault_agent_service_user`)
- Consider using `remove_secret_id_file_after_reading: true` for enhanced security

## Troubleshooting

### Check Vault Agent status
```bash
systemctl status vault-agent
```

### View Vault Agent logs
```bash
journalctl -u vault-agent -f
```

### Verify configuration
```bash
vault agent -config=/etc/vault/agent.hcl -log-level=debug
```

### Check certificate files
```bash
ls -la /etc/nginx/ssl/
openssl x509 -in /etc/nginx/ssl/nginx.homelab.com.crt -text -noout
```

## License

MIT

## Author Information

Created for managing infrastructure certificates with HashiCorp Vault.
