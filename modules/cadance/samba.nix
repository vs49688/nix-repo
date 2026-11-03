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
      "server signing" = "mandatory";
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

    # Finder and Nautilus browse _smb._tcp. Windows does not - it wants
    # WS-Discovery (samba-wsdd) - so this is a macOS/Linux convenience only.
    services.avahi.extraServiceFiles.samba = ''
      <?xml version="1.0" standalone='no'?>
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
          <type>_smb._tcp</type>
          <port>445</port>
        </service>
      </service-group>
    '';
  };
}
