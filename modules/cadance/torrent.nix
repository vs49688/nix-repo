##
# CADANCE module to create a network-sandboxed qBittorrent,
# forced over a VLAN interface.
#
# This is not using NixOS's networking.* or systemd's
# PrivateNetwork= option as the impedance mismatch is too great.
##
{ config, lib, pkgs, ... }:
let
  cfg = config.cadance.containers.torrent;
  ifname = "mv-${cfg.parentInterface}";
in
{
  options.cadance.containers.torrent = with lib; {
    enable = mkEnableOption "Enable Transmission container (via vlan)";

    port = mkOption {
      type = with types; ints.between 1 65536;
    };

    parentInterface = mkOption {
      type = types.str;
    };

    hostAddress = mkOption {
      type = types.str;
    };

    localAddress = mkOption {
      type = types.str;
    };

    downloadDir = mkOption {
      type = types.str;
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/transmission";
    };

    virtualHost = mkOption {
      type = types.str;
    };

    baseUrl = mkOption {
      type = types.str;
    };

    extraCaddyConfig = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.transmission.gid = config.ids.gids.transmission;
    users.users.transmission = {
      isSystemUser = true;
      group        = "transmission";
      uid          = config.ids.uids.transmission;
      home         = cfg.stateDir;
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.stateDir}' 0700 transmission transmission -"
    ];

    ##
    # NB: Do NOT do this, we don't want any possibility of talking out
    #  the non-VPN'd interface.
    ##
    # networking.nat.internalInterfaces   = [ "ve-torrent" ];

    networking.networkmanager.unmanaged = [ "interface-name:ve-torrent" ];

    containers.torrent = {
      autoStart       = true;
      ephemeral       = true;
      privateNetwork  = true;

      macvlans = [ cfg.parentInterface ];

      ##
      # NB: Use an "extra" veth instead of the primary one, as we don't
      #  want a default route added.
      ##
      extraVeths.ve-torrent = {
        hostAddress     = cfg.hostAddress;
        localAddress    = cfg.localAddress;
      };

      bindMounts."/downloads" = {
        hostPath   = cfg.downloadDir;
        isReadOnly = false;
      };

      bindMounts."/var/lib/transmission" = {
        hostPath   = cfg.stateDir;
        isReadOnly = false;
      };

      config = { ... }: {
        users.users.transmission.home = "/var/lib/transmission";

        # Work around https://github.com/NixOS/nixpkgs/issues/162686
        networking.useHostResolvConf = false;

        networking.interfaces.${ifname} = {
          useDHCP    = true;
        };

        networking.firewall.interfaces.${ifname} = {
          allowedTCPPorts = [ cfg.port ];
          allowedUDPPorts = [ cfg.port ];
        };

        networking.firewall.interfaces.ve-torrent.allowedTCPPorts = [ 9091 ];

        services.transmission = {
          enable = true;
          home   = "/var/lib/transmission";

          openRPCPort   = false;
          openPeerPorts = false;

          package = pkgs.transmission_4;

          settings = {
            download-dir   = "/downloads/complete";
            incomplete-dir = "/downloads/incomplete";

            peer-port                 = cfg.port;
            peer-port-random-on-start = false;
            port-forwarding-enabled   = false;

            rpc-enabled                = true;
            rpc-bind-address           = cfg.localAddress;
            rpc-whitelist              = cfg.hostAddress;
            rpc-host-whitelist-enabled = true;
            rpc-host-whitelist         = cfg.virtualHost;

            ratio-limit = 0;
            ratio-limit-enabled = true;
          };
        };

        # https://github.com/NixOS/nixpkgs/issues/258793
        systemd.services.transmission.serviceConfig = {
          RootDirectoryStartOnly = lib.mkForce false;
          RootDirectory = lib.mkForce "";
        };

        time.timeZone = config.time.timeZone;

        system.stateVersion = "22.05";
      };
    };

    systemd.services."container@torrent".bindsTo = [
      "${cfg.parentInterface}-netdev.service"
    ];

    systemd.services."container@torrent".after = [
      "${cfg.parentInterface}-netdev.service"
    ];

    services.caddy.virtualHosts.${cfg.virtualHost}.extraConfig = ''
      redir ${cfg.baseUrl} ${cfg.baseUrl}/
      handle ${cfg.baseUrl}/* {

        ${cfg.extraCaddyConfig}

        reverse_proxy http://${cfg.localAddress}:9091
      }
    '';
  };
}
