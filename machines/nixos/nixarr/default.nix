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
    inputs.nixarr.nixosModules.default
    inputs.copyparty.nixosModules.default

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

  environment.systemPackages = with pkgs; [
    vim
    curl
    git
  ];

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
    secrets."nixarr_wg_conf" = {
      path = "/run/secrets/wg.conf";
      mode = "0600";
    };
    secrets."copyparty/richard/password" = {
      path = "/run/secrets/copyparty/richard_password";
      owner = "copyparty";
      group = "copyparty";
      mode = "0400";
    };
  };

  nixarr = {
    enable = true;
    mediaDir = "/media/data";
    stateDir = "/media/data/.state/nixarr";

    vpn = {
      enable = true;
      wgConf = "/run/secrets/wg.conf";
    };

    qbittorrent = {
      enable = true;
      vpn.enable = true;
    };

    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    sonarr.enable = true;
  };

  # Ensure vault-agent starts after sops secrets are decrypted
  systemd.services.vault-agent-nixarr = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  systemd.services.wg = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 3923 ];

  services = {
    copyparty = {
      enable = true;
      user = "copyparty";
      group = "copyparty";

      settings = {
        i = "0.0.0.0";
      };

      accounts = {
        richard.passwordFile = "/run/secrets/copyparty/richard_password";
      };

      volumes = {
        "/" = {
          path = "/media/data";
          access = {
            r = "*";
            rw = [ "richard" ];
          };
          flags = {
            fk = 4;
            scan = 60;
            e2d = true;
          };
        };
      };
    };

    vault-agent.instances.nixarr = {
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
            source = "/etc/vault/templates/nixarr.homelab.lan.crt.ctmpl";
            destination = "/etc/ssl/certs/nixarr.homelab.lan.crt";
            perms = "0644";
          }
          {
            source = "/etc/vault/templates/nixarr.homelab.lan.key.ctmpl";
            destination = "/etc/ssl/certs/nixarr.homelab.lan.key";
            perms = "0600";
          }
        ];
      };
    };
  };

  # Trust Vault's CA chain system-wide
  security.pki.certificates = [
    (builtins.readFile ../../../certs/vault-ca-chain.pem)
  ];

  # Vault CA cert and consul-template files
  environment.etc = {
    "ssl/certs/vault-ca-chain.pem".source = ../../../certs/vault-ca-chain.pem;
    "vault/templates/nixarr.homelab.lan.crt.ctmpl".source = ./templates/nixarr.homelab.lan.crt.ctmpl;
    "vault/templates/nixarr.homelab.lan.key.ctmpl".source = ./templates/nixarr.homelab.lan.key.ctmpl;
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";
}
