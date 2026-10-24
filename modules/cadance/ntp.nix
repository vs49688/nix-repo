{ lib, config, ... }: {
  options = {
    services.ntpd-rs = with lib; {
      firewallInterfaces = mkOption {
        type = types.listOf types.str;
      };
    };
  };

  config = {
    networking.firewall.interfaces = lib.listToAttrs (
      builtins.map (v: {
        name = v;
        value = { allowedUDPPorts = [ 123 ]; };
      }) config.services.ntpd-rs.firewallInterfaces
    );
  };
}
