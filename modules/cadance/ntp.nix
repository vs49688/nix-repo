{ lib, config, ... }: {
  options = {
    services.ntpd-rs = with lib; {
      firewallInterfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Interfaces on which inbound NTP (UDP 123) is allowed.

          The daemon listens on every address, so without this only the
          globally-allowed ports are reachable. Empty by default, so that a
          host which enables ntpd-rs without naming its networks serves the
          local machine and nothing else.
        '';
      };
    };
  };

  # Opening a port for a daemon that is not running is only ever a mistake.
  config = lib.mkIf config.services.ntpd-rs.enable {
    networking.firewall.interfaces = lib.listToAttrs (
      builtins.map (v: {
        name = v;
        value = { allowedUDPPorts = [ 123 ]; };
      }) config.services.ntpd-rs.firewallInterfaces
    );
  };
}
