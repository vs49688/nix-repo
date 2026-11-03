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
      allowedTCPPorts = [
        139
        445
      ];

      allowedUDPPorts = [
        137
        138
      ];
    };
  };
}
