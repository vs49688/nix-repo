{ config, lib, ... }: let
  lanInterface = config.cadance.settings.lanInterface;
in {
  config = lib.mkIf config.services.samba.enable {
    services.samba.openFirewall = false;
    services.samba.nmbd.enable = false;
    services.samba.winbindd.enable = false;

    services.samba.settings.global = {
      "workgroup" = "WORKGROUP";
      "server string" = "%h";
      "server role" = "standalone server";
      "obey pam restrictions" = "yes";
      "map to guest" = "bad user";
      "local master" = "no";
      "domain master" = "no";
      "preferred master" = "no";
      "security" = "user";
    };

    networking.firewall.interfaces.${lanInterface} = {
      ##
      # nmbd: 137/udp, 138/udp, 139/tcp - explicitly disabled, so don't add them.
      # smbd: only 445/tcp is needed for modern stuff.
      ##
      allowedTCPPorts = [
        445
      ];
    };
  };
}
