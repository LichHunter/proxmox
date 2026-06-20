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
  ];

  # DNS for 192.168.100.x subnet (OPNsense)
  networking.nameservers = [ "192.168.100.1" ];
  networking.search = [ "homelab.lan" ];

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
    defaultSopsFile = ../secrets/gitea.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."gitea_role_id" = {
      path = "/etc/vault/role_id";
      mode = "0600";
    };
    secrets."gitea_secret_id" = {
      path = "/etc/vault/secret_id";
      mode = "0600";
    };
  };

  services.postgresql.enable = true;

  services.gitea = {
    enable = true;
    appName = "Homelab Gitea";
    stateDir = "/var/lib/gitea";

    database = {
      type = "postgres";
      createDatabase = true;
    };

    settings = {
      server = {
        DOMAIN = "gitea.susano-homelab.duckdns.org";
        ROOT_URL = "https://gitea.susano-homelab.duckdns.org/";
        HTTP_PORT = 3000;
        PROTOCOL = "http"; # TLS terminated by Pangolin
        DISABLE_SSH = false;
        START_SSH_SERVER = true; # Use Gitea's built-in SSH server
        SSH_PORT = 2222;
        SSH_LISTEN_PORT = 2222;
        SSH_DOMAIN = "gitea.susano-homelab.duckdns.org";
        BUILTIN_SSH_SERVER_USER = "git"; # Allow standard git@ username
      };

      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = false;
      };

      session = {
        COOKIE_SECURE = true;
      };

      log = {
        LEVEL = "Info";
      };

      repository = {
        ROOT = "/var/lib/gitea/repositories";
      };

      picture = {
        DISABLE_GRAVATAR = true;
      };
    };
  };

  # Ensure vault-agent starts after sops secrets are decrypted
  systemd.services.vault-agent-gitea = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  # Create API token for Homepage dashboard
  systemd.services.gitea-homepage-token = {
    description = "Create Gitea API token for Homepage dashboard";
    after = [ "gitea.service" ];
    requires = [ "gitea.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "gitea";
      RemainAfterExit = true;
      WorkingDirectory = "/var/lib/gitea";
    };

    environment.GITEA_WORK_DIR = "/var/lib/gitea";

    script = ''
      TOKEN_FILE="/var/lib/gitea/homepage-token"

      if [ ! -f "$TOKEN_FILE" ]; then
        echo "Creating Gitea API token for Homepage..."

        ${pkgs.gitea}/bin/gitea admin user generate-access-token \
          --username fujin \
          --token-name homepage-dashboard \
          --scopes "read:repository,read:user,read:organization,read:issue,read:notification" \
          > "$TOKEN_FILE"

        chmod 600 "$TOKEN_FILE"
        echo "Token created and saved to $TOKEN_FILE"
      else
        echo "Token already exists at $TOKEN_FILE"
      fi
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      3000 # Gitea HTTP
      2222 # Gitea SSH (git operations)
    ];
  };

  services.vault-agent.instances.gitea = {
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
          source = "/etc/vault/templates/gitea.homelab.lan.crt.ctmpl";
          destination = "/etc/ssl/certs/gitea.homelab.lan.crt";
          perms = "0644";
        }
        {
          source = "/etc/vault/templates/gitea.homelab.lan.key.ctmpl";
          destination = "/etc/ssl/certs/gitea.homelab.lan.key";
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
    "vault/templates/gitea.homelab.lan.crt.ctmpl".source = ./templates/gitea.homelab.lan.crt.ctmpl;
    "vault/templates/gitea.homelab.lan.key.ctmpl".source = ./templates/gitea.homelab.lan.key.ctmpl;
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
