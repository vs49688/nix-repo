{ config, lib, ... }:
{
  config = lib.mkIf config.services.avahi.enable {
    services.avahi.openFirewall = false;
    services.avahi.allowInterfaces = [ "enp42s0" ];
    services.avahi.nssmdns4 = true;
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = false;

    networking.firewall.interfaces.enp42s0.allowedUDPPorts = [ 5353 ];
  };
}
