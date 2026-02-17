{ config, lib, pkgs, ... }:
let
  cfg = config.cadance.vaultwarden;
  vwCfg = config.services.vaultwarden;
in {
  options.cadance.vaultwarden = with lib; {
    enable = mkEnableOption "Enable CADANCE Vaultwarden";

    hostName = mkOption {
      type = types.str;
      example = "vaultwarden.example.com";
    };

    environmentFile = mkOption {
      type = types.str;
    };

    smtpHost = mkOption {
      type = types.str;
      example = "smtp.example.com";
    };

    smtpFrom = mkOption {
      type = types.str;
      example = "noreply@example.com";
    };

    smtpFromName = mkOption {
      type = types.str;
      example = "My Vaultwarden";
    };

    smtpUsername = mkOption {
      type = types.str;
      example = "noreply@example.com";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql.ensureDatabases = [
      "vaultwarden"
    ];

    services.postgresql.ensureUsers = [
      { name = "vaultwarden"; ensureDBOwnership = true; }
    ];

    services.vaultwarden = {
      enable = true;

      environmentFile = cfg.environmentFile;

      dbBackend = "postgresql";

      config = {
        DOMAIN = "https://${cfg.hostName}";

        REQUIRE_DEVICE_EMAIL = true;
        SIGNUPS_VERIFY = true;

        IP_HEADER = "X-Forwarded-For";

        # FIXME: "unix:/var/run/vaultwarden/vaultwarden.socket" when Rocket is updated
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = "8089";

        DATABASE_URL = "postgresql://vaultwarden@/vaultwarden?host=/run/postgresql";

        USE_SENDMAIL = false;
        SMTP_HOST = cfg.smtpHost;
        SMTP_FROM = cfg.smtpFrom;
        SMTP_FROM_NAME = cfg.smtpFromName;
        SMTP_USERNAME = cfg.smtpUsername;
        # SMTP_PASSWORD = "Set in environment file";

        SIGNUPS_ALLOWED = false;
      };
    };

    systemd.services.vaultwarden = {
      requires = [ "postgresql.target" ];

      confinement.enable   = true;
      confinement.mode     = "full-apivfs";
      confinement.binSh    = "${pkgs.bash}/bin/sh";
      confinement.configureNetworking = true;
      # confinement.configureSendmail = true;
      confinement.packages = [
        vwCfg.webVaultPackage
      ];

      serviceConfig = {
        BindReadOnlyPaths = [
          "/run/postgresql" # For Postgres socket
          vwCfg.environmentFile
        ];
      };
    };

    services.caddy.virtualHosts.${cfg.hostName}.extraConfig = ''
      reverse_proxy http://${vwCfg.config.ROCKET_ADDRESS}:${vwCfg.config.ROCKET_PORT}
    '';
  };
}
