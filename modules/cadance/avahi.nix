{ config, lib, ... }: let
  lanInterface = config.cadance.settings.lanInterface;
in {
  config = lib.mkIf config.services.avahi.enable {
    services.avahi.openFirewall = false;
    services.avahi.nssmdns4 = true;
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = false;

    services.avahi.settings.server.allow-interfaces = [ lanInterface ];

    networking.firewall.interfaces.${lanInterface}.allowedUDPPorts = [ 5353 ];

    environment.etc."avahi/hosts".text = ''
      10.0.102.10 BRW9CAD97B3AF49.local
    '';

    # TXT below is the printer's own record, taken from its mDNS announcements
    # (`tcpdump -i switch0.102 -vvv udp port 5353`) rather than reconstructed:
    # rp, pdl, URF, UUID and ty all agree with `ipptool get-printer-attributes`,
    # and the rest (usb_*, kind, PaperMax, print_wfds, ...) only exist in its mDNS.
    services.avahi.extraServiceFiles = {
      BRW9CAD97B3AF49 = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name>Brother MFC-L2703DW</name>
          <service>
            <type>_ipp._tcp</type>
            <subtype>_universal._sub._ipp._tcp</subtype>
            <host-name>BRW9CAD97B3AF49.local.</host-name>
            <port>631</port>
            <txt-record>txtvers=1</txt-record>
            <txt-record>qtotal=1</txt-record>
            <txt-record>rp=ipp/print</txt-record>
            <txt-record>ty=Brother MFC-L2700DW series</txt-record>
            <txt-record>product=(Brother MFC-L2700DW series)</txt-record>
            <txt-record>pdl=application/octet-stream,image/urf,image/pwg-raster</txt-record>
            <txt-record>URF=W8,CP1,IS4-1,MT1-3-4-5-8,OB10,PQ4,RS200-300-600,V1.3,DM1</txt-record>
            <txt-record>UUID=e3248000-80ce-11db-8000-30055c667ce3</txt-record>
            <txt-record>note=</txt-record>
            <txt-record>priority=25</txt-record>
            <txt-record>kind=document,envelope,label</txt-record>
            <txt-record>PaperMax=legal-A4</txt-record>
            <txt-record>Color=F</txt-record>
            <txt-record>Duplex=T</txt-record>
            <txt-record>Fax=T</txt-record>
            <txt-record>Scan=T</txt-record>
            <txt-record>Copies=T</txt-record>
            <txt-record>PaperCustom=T</txt-record>
            <txt-record>Binary=T</txt-record>
            <txt-record>Transparent=T</txt-record>
            <txt-record>TBCP=F</txt-record>
            <txt-record>usb_MFG=Brother</txt-record>
            <txt-record>usb_MDL=MFC-L2700DW series</txt-record>
            <txt-record>usb_CMD=PJL,HBP,URF</txt-record>
            <txt-record>rfo=ipp/faxout</txt-record>
            <txt-record>print_wfds=T</txt-record>
            <txt-record>adminurl=http://BRW9CAD97B3AF49.local./net/net/airprint.html</txt-record>
          </service>
        </service-group>
      '';
    };
  };
}
