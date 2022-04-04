##
# CADANCE Module that locks Unifi Controller
# in a container and configures nginx.
##
{ config, pkgs, lib, ... }:
let
  cfg = config.cadance.containers.unifi;
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
  };

  config = lib.mkIf cfg.enable {
    networking.nat.internalInterfaces = [ "ve-${cfg.containerName}" ];
    networking.networkmanager.unmanaged = [ "interface-name:ve-${cfg.containerName}" ];

    networking.firewall = {
      # https://help.ubnt.com/hc/en-us/articles/218506997
      allowedTCPPorts = [
        8080  # Port for UAP to inform controller.
      ];
      allowedUDPPorts = [
        3478  # UDP port used for STUN.
        10001 # UDP port used for device discovery.
      ];
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0700 root - - -"
    ];

    containers.${cfg.containerName} = {
      ephemeral      = true;
      privateNetwork = true;
      hostAddress    = cfg.hostAddress;
      localAddress   = cfg.localAddress;

      forwardPorts = [
        { protocol = "tcp"; hostPort = 8080;  containerPort = 8080; }
        { protocol = "udp"; hostPort = 3478;  containerPort = 3478; }
        { protocol = "udp"; hostPort = 10001; containerPort = 10001; }
      ];

      # Can't bind directly to /var/lib/unifi as the
      # service already does this.
      bindMounts."/var/lib/unifi" = {
        hostPath   = cfg.dataDir;
        isReadOnly = false;
      };

      config = { config, pkgs, ... }: {
        nixpkgs.config.allowUnfree = true;

        networking.firewall.allowedTCPPorts = [ 8443 ];

        services.unifi = {
          enable    = true;
          openPorts = true;
        };

        system.stateVersion = "21.05";
      };
    };

    services.nginx.virtualHosts.${cfg.virtualHost} = {
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
  };
}
