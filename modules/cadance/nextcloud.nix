##
# CADANCE module to run a Nextcloud container.
##
{ config, pkgs, lib, ... }:
let
  cfg = config.cadance.containers.nextcloud;
in {
  options.cadance.containers.nextcloud = with lib; {
    enable = mkOption {
      default = false;
      type = types.bool;
      description = "Enable NextCloud container";
    };

    package = mkOption {
      type = types.package;
      description = "Which package to use for the Nextcloud instance.";
      relatedPackages = [ "nextcloud22" "nextcloud23" ];
    };

    containerName = mkOption {
      type = types.str;
      default = "nextcloud";
    };

    hostAddress = mkOption {
      type = types.str;
    };

    localAddress = mkOption {
      type = types.str;
    };

    virtualHost = mkOption {
      type = types.str;
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/nextcloud";
    };

    uid = mkOption {
      type = types.int;
    };

    gid = mkOption {
      type = types.int;
    };

    adminpassFile = mkOption {
      type = types.str;
    };

    extraConfig = {
      dbtype = mkOption {
        type = types.enum [ "sqlite" "pgsql" "mysql" ];
        default = "sqlite";
        description = "Database type.";
      };
      dbname = mkOption {
        type = types.nullOr types.str;
        default = "nextcloud";
        description = "Database name.";
      };
      dbuser = mkOption {
        type = types.nullOr types.str;
        default = "nextcloud";
        description = "Database user.";
      };
      dbpassFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The full path to a file that contains the database password.
        '';
      };
      dbhost = mkOption {
        type = types.nullOr types.str;
        default = "localhost";
        description = ''
          Database host.
          Note: for using Unix authentication with PostgreSQL, this should be
          set to <literal>/run/postgresql</literal>.
        '';
      };
      dbport = mkOption {
        type = with types; nullOr (either int str);
        default = null;
        description = "Database port.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.nextcloud.gid = cfg.gid;
    users.users.nextcloud = {
      # NB: This needs both otherwise it errors...
      isSystemUser = true;
      isNormalUser = false;
      group        = "nextcloud";
      uid          = cfg.uid;
      home         = cfg.stateDir;
    };

    networking.nat.internalInterfaces   = [ "ve-${cfg.containerName}" ];
    networking.networkmanager.unmanaged = [ "interface-name:ve-${cfg.containerName}" ];

    containers.${cfg.containerName} = {
      autoStart      = true;
      ephemeral      = true;
      privateNetwork = true;
      hostAddress    = cfg.hostAddress;
      localAddress   = cfg.localAddress;
      timeoutStartSec = "10min";

      bindMounts."/adminpass" = {
        hostPath   = cfg.adminpassFile;
        isReadOnly = true;
      };

      bindMounts."/var/lib/nextcloud" = {
        hostPath   = cfg.stateDir;
        isReadOnly = false;
      };

      config = { config, pkgs, ... }: {
        networking.firewall.allowedTCPPorts = [ 80 ];

        services.nextcloud = {
          enable   = true;
          https    = true;
          hostName = cfg.virtualHost;
          package  = cfg.package;
          config = cfg.extraConfig // {
            adminpassFile = "/adminpass";
          };
        };

        systemd.services.nextcloud-setup = {
          unitConfig.RequiresMountsFor = ["/var/lib/nextcloud" ];
          wants = [ "network-online.target" ];
        };

        users.groups.nextcloud.gid = cfg.gid;
        users.users.nextcloud.uid  = cfg.uid;

        system.stateVersion = "21.05";
      };
    };

    services.nginx.virtualHosts.${cfg.virtualHost} = {
      locations."/" = {
        priority  = 1;
        proxyPass = "http://${cfg.localAddress}:80";
        extraConfig = ''
          proxy_request_buffering off;
          proxy_buffering         off;
          proxy_connect_timeout   60m;
          proxy_read_timeout      60m;
          proxy_send_timeout      60m;
        '';
      };
    };
  };
}
