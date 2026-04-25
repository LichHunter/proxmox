# Ansible

## Pre-setup

1. Terraform infrastructure must be applied first (`terraform/main.tf`) — creates Vault and CA containers on Proxmox
2. SSH keys must be saved to `.secrets/`:
   ```
   cd ../terraform
   tofu output -raw vault_private_key > ../.secrets/vault_key && chmod 600 ../.secrets/vault_key
   tofu output -raw root_ca_private_key > ../.secrets/root-ca_key && chmod 600 ../.secrets/root-ca_key
   ```
3. Gitea personal access token must be created and saved:
   ```
   echo -n "YOUR_TOKEN" > ../.secrets/gitea_token && chmod 600 ../.secrets/gitea_token
   ```
4. The `Proxmox-Vault` Gitea repository must have the updated Terraform config (PKI-only, no root CA mount)

## Configure Vault

```
ansible-playbook playbooks/vault.yml
```

Single command, fully idempotent. Safe to re-run at any point.

**What it does:**

1. Starts the CA machine if needed
2. Generates root CA → intermediate CA → Vault server cert (all on CA machine)
3. Deploys certs to Vault, installs and starts Vault with TLS
4. Initializes and unseals Vault
5. Imports intermediate CA into Vault's PKI engine
6. Clones Terraform vault config from Gitea, runs `tofu apply` (roles, ACME, URLs, policies)
7. Shuts down the CA machine

**Secrets created on first run (in `.secrets/`):**

- `root_ca_passphrase` — root CA key passphrase (auto-generated)
- `vault_init_data.json` — Vault unseal keys and root token

**Tags for partial runs:**

| Tag | Plays |
|-----|-------|
| `preflight` | Check PKI state, start CA if needed |
| `root_ca` | Generate certificates on CA machine |
| `vault` | Deploy certs, install Vault, init, unseal, import intermediate |
| `terraform` | Clone repo, tofu init/apply |
| `shutdown_ca` | Stop CA container |
