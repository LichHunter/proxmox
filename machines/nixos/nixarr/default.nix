{
  modulesPath,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    inputs.sops-nix.nixosModules.sops
    ../modules/network.nix
  ];

  proxmoxLXC = {
    privileged = false;
    manageNetwork = false;
    manageHostName = false;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  sops = {
    defaultSopsFile = ../secrets/nixarr.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."nixarr_role_id" = {
      path = "/etc/vault/role_id";
      mode = "0600";
    };
    secrets."nixarr_secret_id" = {
      path = "/etc/vault/secret_id";
      mode = "0600";
    };
  };

  # Ensure vault-agent starts after sops secrets are decrypted
  systemd.services.vault-agent-nixarr = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  services.vault-agent.instances.nixarr = {
    settings = {
      vault = {
        address = "https://vault.homelab.lan:8200";
        ca_cert = "/etc/ssl/certs/vault-ca-chain.pem";
      };

      auto_auth = {
        method = [
          {
            type = "approle";
            mount_path = "auth/approle";
            config = {
              role_id_file_path = "/etc/vault/role_id";
              secret_id_file_path = "/etc/vault/secret_id";
              remove_secret_id_file_after_reading = false;
            };
          }
        ];

        sink = [
          {
            type = "file";
            config = {
              path = "/tmp/vault-token";
            };
          }
        ];
      };

      template = [
        {
          source = "/etc/vault/templates/nix-arr.homelab.lan.crt.ctmpl";
          destination = "/etc/ssl/certs/nix-arr.homelab.lan.crt";
          perms = "0644";
        }
        {
          source = "/etc/vault/templates/nix-arr.homelab.lan.key.ctmpl";
          destination = "/etc/ssl/certs/nix-arr.homelab.lan.key";
          perms = "0600";
        }
      ];
    };
  };

  # Trust Vault's CA chain system-wide
  security.pki.certificates = [
    (builtins.readFile ../../../certs/vault-ca-chain.pem)
  ];

  # Vault CA cert and consul-template files
  environment.etc = {
    "ssl/certs/vault-ca-chain.pem".source = ../../../certs/vault-ca-chain.pem;
    "vault/templates/nix-arr.homelab.lan.crt.ctmpl".source = ./templates/nix-arr.homelab.lan.crt.ctmpl;
    "vault/templates/nix-arr.homelab.lan.key.ctmpl".source = ./templates/nix-arr.homelab.lan.key.ctmpl;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    curl
    git
  ];

  system.stateVersion = "25.11";
}
