{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkPackageOption
    mkIf
    mkMerge
    types
    attrNames
    concatStringsSep
    concatMapStringsSep
    imap0
    toUpper
    ;

  cfg = config.services.unpackerr;
  format = pkgs.formats.toml { };
  configFile = format.generate "unpackerr.conf" cfg.settings;

  # Extract API key from a Starr app's config.xml
  extractKeyScript = envVar: configPath: ''
    if [ -f "${configPath}" ]; then
      KEY=$(${pkgs.gnugrep}/bin/grep -oP '<ApiKey>\K[^<]+' "${configPath}")
      if [ -n "$KEY" ]; then
        echo "${envVar}=$KEY" >> "$RUNTIME_DIRECTORY/env"
      fi
    fi
  '';
in
{
  options.services.unpackerr = {
    enable = mkEnableOption "Unpackerr, a service to extract downloads for Starr apps";

    package = mkPackageOption pkgs "unpackerr" { };

    settings = mkOption {
      type = format.type;
      default = {
        debug = false;
      };
      description = ''
        Unpackerr configuration in TOML format.
        Refer to <https://unpackerr.zip/docs/install/configuration> for details.

        When using autoApiKeys, API keys are read from each app's config.xml
        at service start — no need to configure them manually.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "unpackerr";
      description = "User account under which Unpackerr runs.";
    };

    group = mkOption {
      type = types.str;
      default = "media";
      description = "Group under which Unpackerr runs.";
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        List of environment files to pass to the systemd service.
        Useful for passing additional secrets via environment variables.
      '';
    };

    autoApiKeys = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = {
        lidarr = "/var/lib/lidarr/config.xml";
        radarr = "/var/lib/radarr/config.xml";
      };
      description = ''
        Automatically extract API keys from Starr app config.xml files at
        service start. Keys are the app name (lidarr, radarr, sonarr, etc.),
        values are paths to the app's config.xml.
      '';
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/unpackerr";
      description = "State directory for Unpackerr.";
    };

    extractDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/media/data/unpackerr";
      description = ''
        Directory where Unpackerr writes extracted files.
        Created automatically with correct ownership if set.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users = mkIf (cfg.user == "unpackerr") {
      unpackerr = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
      };
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ]
    ++ lib.optional (cfg.extractDir != null) "d '${cfg.extractDir}' 0775 ${cfg.user} ${cfg.group} - -";

    systemd.services.unpackerr = {
      description = "Extracts downloads for Radarr, Sonarr, Lidarr, and others";
      after = [ "network-online.target" ] ++ map (app: "${app}.service") (attrNames cfg.autoApiKeys);
      requires = map (app: "${app}.service") (attrNames cfg.autoApiKeys);
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = mkMerge [
        {
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${cfg.package}/bin/unpackerr -c ${configFile}";
          Restart = "on-failure";
          RestartSec = "10s";
          WorkingDirectory = cfg.dataDir;
          EnvironmentFile = cfg.environmentFiles;
          NoNewPrivileges = true;
          PrivateTmp = true;
        }
        (mkIf (cfg.autoApiKeys != { }) {
          RuntimeDirectory = "unpackerr";
          EnvironmentFile = cfg.environmentFiles ++ [ "-/run/unpackerr/env" ];
          ExecStartPre = [
            (
              "+"
              + pkgs.writeShellScript "unpackerr-extract-keys" ''
                RUNTIME_DIRECTORY=/run/unpackerr
                mkdir -p "$RUNTIME_DIRECTORY"
                rm -f "$RUNTIME_DIRECTORY/env"
                touch "$RUNTIME_DIRECTORY/env"
                ${concatStringsSep "\n" (
                  lib.mapAttrsToList (
                    app: configPath:
                    let
                      # Support multiple instances: UN_LIDARR_0_API_KEY
                      envVar = "UN_${toUpper app}_0_API_KEY";
                    in
                    extractKeyScript envVar configPath
                  ) cfg.autoApiKeys
                )}
                chown ${cfg.user}:${cfg.group} "$RUNTIME_DIRECTORY/env"
                chmod 0400 "$RUNTIME_DIRECTORY/env"
              ''
            )
          ];
        })
      ];
    };
  };
}
