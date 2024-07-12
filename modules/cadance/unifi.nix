##
# CADANCE Module that locks Unifi Controller
# in a container and configures nginx.
##
{ config, pkgs, lib, ... }:
let
  cfg = config.cadance.containers.unifi;
  mvName = "mv-${cfg.managementInterface}";
  vethName = "ve-${cfg.containerName}";
in {
  options.cadance.containers.unifi = with lib; {
    enable = mkOption {
      default     = false;
      type        = types.bool;
      description = "Enable UniFi container";
    };

    containerName = mkOption {
      type    = types.str;
      default = "unifi";
    };

    dataDir = mkOption {
      type    = types.str;
      default = "/var/lib/unifi/data";
    };

    mongodbPackage = mkPackageOption pkgs "mongodb" {
      default = "mongodb-4_4";
      extraDescription = ''
        ::: {.note}
        unifi7 officially only supports mongodb up until 3.6 but works with 4.4.
        :::
      '';
    };

    mongodbDataDir = mkOption {
      type = types.str;
      default = "/var/db/mongodb-unifi";
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

    extraNginxConfig = mkOption {
      type = types.str;
      default = "";
    };

    managementInterface = mkOption {
      type = types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.unmanaged = [ "interface-name:${vethName}" ];

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0700 root - - -"
    ];

    containers.${cfg.containerName} = {
      autoStart      = true;
      ephemeral      = true;
      privateNetwork = true;

      macvlans = [ cfg.managementInterface ];

      ##
      # NB: Use an "extra" veth instead of the primary one, as we don't
      #  want a default route added.
      ##
      extraVeths.${vethName} = {
        hostAddress     = cfg.hostAddress;
        localAddress    = cfg.localAddress;
      };

      # Can't bind directly to /var/lib/unifi as the
      # service already does this.
      bindMounts."/var/lib/unifi" = {
        hostPath   = cfg.dataDir;
        isReadOnly = false;
      };

      bindMounts."/var/db/mongodb" = {
        hostPath = cfg.mongodbDataDir;
        isReadOnly = false;
      };

      config = { config, pkgs, ... }: {
        nixpkgs.config.allowUnfree = true;

        networking.interfaces.${mvName} = {
          useDHCP = true;
        };

        networking.firewall.interfaces.${vethName} = {
          allowedTCPPorts = [ 8443 ];
        };

        networking.firewall.interfaces.${mvName} = {
          # https://help.ubnt.com/hc/en-us/articles/218506997
          allowedTCPPorts = [
            8080  # Port for UAP to inform controller.
          ];
          allowedUDPPorts = [
            3478  # UDP port used for STUN.
            10001 # UDP port used for device discovery.
          ];
        };

        environment.systemPackages = with pkgs; [
          cfg.mongodbPackage
          mongodb-tools
          mongosh
          jq
        ];

        services.mongodb.enable = true;
        services.mongodb.package = cfg.mongodbPackage;
        services.mongodb.enableAuth = false;
        services.mongodb.bind_ip = "127.0.0.1";

        services.unifi = {
          enable       = true;
          openFirewall = true;
          unifiPackage = pkgs.unifi;
          mongodbPackage = pkgs.writeShellScriptBin "mongod" ''
            exec ${pkgs.coreutils}/bin/true
          '';
        };

        systemd.services.unifi.after = [ "mongodb.service" ];
        systemd.services.unifi.requires = [ "mongodb.service" ];

        system.stateVersion = "21.05";
      };
    };

    services.nginx.virtualHosts.${cfg.virtualHost} = lib.mkIf config.services.nginx.enable {
      locations."/" = {
        priority    = 1;
        proxyPass   = "https://${cfg.localAddress}:8443";
        extraConfig = cfg.extraNginxConfig;
      };

      locations."/ws" = {
        priority        = 1;
        proxyPass       = "https://${cfg.localAddress}:8443/ws";
        proxyWebsockets = true;
        extraConfig     = cfg.extraNginxConfig;
      };
    };

    services.caddy.virtualHosts.${cfg.virtualHost}.extraConfig = lib.mkIf config.services.caddy.enable ''
      reverse_proxy https://${cfg.localAddress}:8443 {
          transport http {
              tls_insecure_skip_verify
          }
      }
    '';
  };
}
