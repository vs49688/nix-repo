{ config, lib, pkgs, ... }:
{
  options.services.kdeconnect = with lib; {
    enable = mkOption {
      default = false;
      type = types.bool;
      description = "Enable KDEConnect";
    };
  };

  config = lib.mkIf config.services.kdeconnect.enable {
    environment.systemPackages = [ pkgs.kdeconnect ];

    networking.firewall.allowedTCPPortRanges = [
      { from = 1714; to = 1764; }
    ];

    networking.firewall.allowedUDPPortRanges = [
      { from = 1714; to = 1764; }
    ];
  };
}
