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
    ../modules/unpackerr.nix
  ];

  proxmoxLXC = {
    privileged = false;
    manageNetwork = false;
    manageHostName = false;
  };

  users.users.syncthing.extraGroups = [ "media" ];
  users.users.copyparty.extraGroups = [ "media" ];

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
    secrets."syncthing/admin/password" = {
      path = "/run/secrets/syncthing/admin_password";
      owner = "syncthing";
      group = "syncthing";
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
      extraSettings = {
        Preferences.WebUI = {
          Password_PBKDF2 = "@ByteArray(bml4YXJyLXFiaXQtc2FsdA==:tG2AJNCoNkv+KYTD1jSWFu6XtdJrPDbkQ4eXqvnjSASbmmGJwqJVOyqWjWuHqAluurKkN/x816SKnXYA09ECeQ==)";
          HostHeaderValidation = false;
          CSRFProtection = false;
        };
      };
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

  networking.firewall = {
    allowedTCPPorts = [
      3923 # copyparty
      8384 # syncthing web ui
      22000 # syncthing transfer
    ];
    allowedUDPPorts = [
      21027 # syncthing discovery
      22000 # syncthing quic
    ];
  };

  services = {
    unpackerr = {
      enable = true;
      group = "media";
      extractDir = "/media/data/unpackerr";
      autoApiKeys = {
        lidarr = "/media/data/.state/nixarr/lidarr/config.xml";
      };
      settings = {
        debug = false;
        webserver = {
          metrics = true;
          listen_addr = "0.0.0.0:5656";
        };
        interval = "2m";
        start_delay = "1m";
        retry_delay = "5m";
        max_retries = 3;
        parallel = 1;
        lidarr = [
          {
            url = "http://localhost:8686";
            paths = [ "/media/data/torrents" ];
            protocols = "torrent,TorrentDownloadProtocol";
            timeout = "10s";
            delete_delay = "5m";
            delete_orig = false;
            split_flac = true;
          }
        ];
        folder = [
          {
            path = "/media/data/torrents";
            extract_path = "/media/data/unpackerr";
            delete_after = "10m";
            delete_files = false;
            delete_original = false;
            move_back = false;
          }
        ];
      };
    };

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:8384";
      dataDir = "/var/lib/syncthing";
      guiPasswordFile = "/run/secrets/syncthing/admin_password";
      settings = {
        gui.user = "admin";
        devices = {
          "phone" = {
            id = "SDY4SXN-GIRMN6O-2JP3KMP-X62J4AZ-BJVU44Z-NGZQZZS-XX32HWS-FHLH6AZ";
          };
        };
        folders = {
          "music" = {
            path = "/media/data/library/music";
            label = "Lidarr Music";
            devices = [ "phone" ];
          };
        };
      };
    };

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
