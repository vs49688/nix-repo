{ config, pkgs, lib, ... }:
let
  cfg = config.services.mailpump;

  # Escape as required by: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
  escapeUnitName = name:
    lib.concatMapStrings (s: if lib.isList s then "-" else s)
      (builtins.split "[^a-zA-Z0-9_.\\-]+" name);

  imapModule = with lib; types.submodule {
    options = {
      url          = mkOption { type = types.str; example = "imaps://imap.mail.yahoo.com/INBOX"; };
      username     = mkOption { type = types.str; };
      passwordFile = mkOption { type = types.str; };
      verifyTLS    = mkOption { type = types.bool; default = true; };

      transport = mkOption {
        type    = types.enum [ "persistent" "standard" ];
        default = "persistent";
      };
    };
  };

  makeService = name: instance: {
    description = "MailPump service, ${instance.source.url} -> ${instance.destination.url}";
    after       = [ "network.target" ];
    wantedBy    = [ "multi-user.target" ];

    environment = {
      MAILPUMP_SOURCE_URL              = instance.source.url;
      MAILPUMP_SOURCE_USERNAME         = instance.source.username;
      MAILPUMP_SOURCE_TLS_SKIP_VERIFTY = lib.boolToString (!instance.source.verifyTLS);
      MAILPUMP_SOURCE_TRANSPORT        = instance.source.transport;

      MAILPUMP_DEST_URL                = instance.destination.url;
      MAILPUMP_DEST_USERNAME           = instance.destination.username;
      MAILPUMP_DEST_TLS_SKIP_VERIFY    = lib.boolToString (!instance.destination.verifyTLS);
      MAILPUMP_DEST_TRANSPORT          = instance.destination.transport;

      MAILPUMP_IDLE_FALLBACK_INTERVAL  = "${toString instance.idleFallbackInterval}s";
      MAILPUMP_BATCH_SIZE              = "${toString instance.batchSize}";
      MAILPUMP_FETCH_BUFFER_SIZE       = "${toString instance.fetchBufferSize}";
      MAILPUMP_FETCH_MAX_INTERVAL      = "${toString instance.fetchMaxInterval}s";
      MAILPUMP_LOG_LEVEL               = "${toString instance.logLevel}";
    };

    serviceConfig = {
      LoadCredential = [
        "password-source:${instance.source.passwordFile}"
        "password-dest:${instance.destination.passwordFile}"
      ];

      # NB: DynamicUser shakes things up a bit
      ExecStart = ''
        ${pkgs.mailpump}/bin/mailpump \
          --source-password-file=''${CREDENTIALS_DIRECTORY}/password-source \
          --dest-password-file=''${CREDENTIALS_DIRECTORY}/password-dest
      '';

      DynamicUser = true;
      StateDirectory = "mailpump";
      RuntimeDirectory = "mailpump/${escapeUnitName name}";
      RootDirectory = "/run/mailpump/${escapeUnitName name}";
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
in {
  options.services.mailpump = with lib; {
    enable = mkOption {
      default = false;
      type = types.bool;
    };

    instances = mkOption {
      default = {};
      type = with types; attrsOf(submodule(name: {
        options = {
          source               = mkOption { type = imapModule; };
          destination          = mkOption { type = imapModule; };
          idleFallbackInterval = mkOption { type = types.ints.positive; default = 60; };
          batchSize            = mkOption { type = types.ints.positive; default = 15; };
          fetchBufferSize      = mkOption { type = types.ints.positive; default = 20; };
          fetchMaxInterval     = mkOption { type = types.ints.positive; default = 300; };

          logLevel = mkOption {
            type    = types.enum [ "panic" "fatal" "error" "warn" "warning" "info" "debug" "trace" ];
            default = "info";
          };

          logFormat = mkOption {
            type    = types.enum [ "json" "text" ];
            default = "text";
          };
        };
      }));
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.mapAttrs' (k: v: lib.nameValuePair ("mailpump@${k}") (makeService k v)) cfg.instances;
  };
}
