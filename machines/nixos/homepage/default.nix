{
  modulesPath,
  pkgs,
  inputs,
  config,
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
  ];

  sops = {
    defaultSopsFile = ../secrets/homepage.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."proxmox_token_id" = { };
    secrets."proxmox_token_secret" = { };
    secrets."gitea_token" = { };
    secrets."homepage_role_id" = {
      path = "/etc/vault/role_id";
      mode = "0600";
    };
    secrets."homepage_secret_id" = {
      path = "/etc/vault/secret_id";
      mode = "0600";
    };

    templates."homepage-secrets.env" = {
      content = ''
        HOMEPAGE_VAR_PROXMOX_USER=${config.sops.placeholder."proxmox_token_id"}
        HOMEPAGE_VAR_PROXMOX_TOKEN=${config.sops.placeholder."proxmox_token_secret"}
        HOMEPAGE_VAR_GITEA_TOKEN=${config.sops.placeholder."gitea_token"}
      '';
      owner = "root";
    };
  };

  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "homepage.homelab.lan,localhost";

    environmentFiles = [ config.sops.templates."homepage-secrets.env".path ];

    services = [
      {
        "Infrastructure" = [
          {
            "Proxmox" = {
              href = "https://192.168.100.10:8006";
              icon = "proxmox";
              description = "Hypervisor";
              widget = {
                type = "proxmox";
                url = "https://192.168.100.10:8006";
                username = "{{HOMEPAGE_VAR_PROXMOX_USER}}";
                password = "{{HOMEPAGE_VAR_PROXMOX_TOKEN}}";
                node = "pve";
              };
            };
          }
          {
            "Vault" = {
              href = "https://vault.homelab.lan:8200";
              icon = "vault";
              description = "Secrets management";
              widget = {
                type = "customapi";
                url = "https://vault.homelab.lan:8200/v1/sys/health";
                mappings = [
                  {
                    field = "initialized";
                    label = "Initialized";
                  }
                  {
                    field = "sealed";
                    label = "Sealed";
                  }
                ];
              };
            };
          }
          {
            "Authentik" = {
              href = "https://authentik.homelab.lan:9443";
              icon = "authentik";
              description = "Identity provider";
              ping = "192.168.100.52";
            };
          }
        ];
      }
      {
        "Services" = [
          {
            "Gitea" = {
              href = "https://gitea.susano-homelab.duckdns.org";
              icon = "gitea";
              description = "Git hosting";
              widget = {
                type = "gitea";
                url = "https://gitea.susano-homelab.duckdns.org";
                key = "{{HOMEPAGE_VAR_GITEA_TOKEN}}";
              };
            };
          }
        ];
      }
    ];

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
    ];

    settings = {
      title = "Homelab";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      base = "https://homepage.homelab.lan";
      layout = {
        Infrastructure = {
          style = "row";
          columns = 3;
        };
        Services = {
          style = "row";
          columns = 3;
        };
      };
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."homepage.homelab.lan" = {
      forceSSL = true;
      sslCertificate = "/etc/ssl/certs/homepage.homelab.lan.crt";
      sslCertificateKey = "/etc/ssl/certs/homepage.homelab.lan.key";

      locations."/" = {
        proxyPass = "http://127.0.0.1:8082";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      443 # HTTPS (nginx)
    ];
  };

  systemd.services.vault-agent-homepage = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  services.vault-agent.instances.homepage = {
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
          source = "/etc/vault/templates/homepage.homelab.lan.crt.ctmpl";
          destination = "/etc/ssl/certs/homepage.homelab.lan.crt";
          perms = "0644";
        }
        {
          source = "/etc/vault/templates/homepage.homelab.lan.key.ctmpl";
          destination = "/etc/ssl/certs/homepage.homelab.lan.key";
          perms = "0640";
          group = "nginx";
        }
      ];
    };
  };

  security.pki.certificates = [
    (builtins.readFile ../../../certs/vault-ca-chain.pem)
  ];

  environment.etc = {
    "ssl/certs/vault-ca-chain.pem".source = ../../../certs/vault-ca-chain.pem;
    "vault/templates/homepage.homelab.lan.crt.ctmpl".source =
      ./templates/homepage.homelab.lan.crt.ctmpl;
    "vault/templates/homepage.homelab.lan.key.ctmpl".source =
      ./templates/homepage.homelab.lan.key.ctmpl;
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
