{ config, pkgs, lib, ... }:
let
  cfg = config.services.mailpump;

  settingsFormat = pkgs.formats.json {};

  # Does the connection have a password_file
  hasPasswordFile = conn: (builtins.hasAttr "password_file" conn) && conn.password_file != "";

  # Map the password file to a systemd credential using the slug.
  patchConnection = slug: conn:
    (builtins.removeAttrs conn ["password_file"]) //
    (lib.optionals (hasPasswordFile conn) { systemd_credential = slug; })
  ;

  patchSources = builtins.mapAttrs (k: v: v // { connection = patchConnection k v.connection; });

  patchConfig = cfg: cfg // {
    destination = patchConnection "destination" cfg.destination;
    sources     = patchSources cfg.sources;
  };

  settingsJSON = settingsFormat.generate "config.json" (patchConfig cfg.settings);
in {
  options.services.mailpump = with lib; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };

    settings = mkOption {
      type = settingsFormat.type;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mailpump = {
      description = "MailPump Multi service";
      after       = [ "network.target" ];
      wantedBy    = [ "multi-user.target" ];

      serviceConfig = {
        LoadCredential = []
          ++ builtins.filter (x: x != "") (lib.mapAttrsToList (k: v: if (hasPasswordFile v.connection) then "${k}:${v.connection.password_file}" else "") cfg.settings.sources)
          ++ lib.optionals (hasPasswordFile cfg.settings.destination) ["destination:${cfg.settings.destination.password_file}"];

        ExecStart = ''
          ${pkgs.mailpump}/bin/mailpump run-multi --config=${settingsJSON}
        '';

        DynamicUser = true;
        StateDirectory = "mailpump";
        RuntimeDirectory = "mailpump";
        RootDirectory = "/run/mailpump";
        ReadWritePaths = "";
        BindReadOnlyPaths = [
          builtins.storeDir
          "/etc/resolv.conf"
          "/etc/ssl/certs"
          "/etc/static/ssl/certs"
        ];
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@network-io" "@system-service" ];
        RestrictRealtime = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        UMask = "0066";
        ProtectHostname = true;
      };
    };
  };
}
