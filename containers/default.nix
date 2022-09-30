{ lib, imagePrefix, pkgs }: let
  callPackage = lib.callPackageWith (pkgs // { inherit imagePrefix; });

  makeStaticServeContainer = a@{ ... }: pkgs.makeStaticServeContainer ({
    inherit imagePrefix;
  } // a);

  makeMaintContainer = { name, tag, text }: makeStaticServeContainer {
    inherit name tag;
    staticPath = pkgs.writeTextDir "index.html" ''<!DOCTYPE html>
<html>
    <head>
        <title>Down for Maintenance</title>
    </head>
    <body>
        <h1>Down for Maintenance</h1>
        <p>The ${text} is currently down for maintenance.</p>
        <p>Please try again later.</p>
    </body>
</html>'';
  };
in {
  inherit imagePrefix;

  mangostwo-realmd = callPackage ./mangostwo-realmd { };
  mangostwo-mangosd = callPackage ./mangostwo-mangosd { };

  navidrome = callPackage ./navidrome { };

  navidrome-mbz = callPackage ./navidrome {
    navidrome = pkgs.navidrome-mbz;
  };

  nimrod-portal-backend = callPackage ./spring-base {
    pkg  = pkgs.nimrod-portal-backend;
    args = ["run"];
  };

  portal-client = callPackage ./spring-base {
    pkg  = pkgs.portal-client;
    args = ["run"];
  };

  portal-client_1_0_4 = callPackage ./spring-base {
    pkg = pkgs.portal-client_1_0_4;
  };

  portal-resource-server = callPackage ./spring-base {
    pkg   = pkgs.portal-resource-server;
    ##
    # NB: The OpenSSH closure is huge! It should probably be split into
    #     separate server/client packages...
    ##
    extra = with pkgs; [ openssh ];
  };

  nimrod-portal = makeStaticServeContainer { pkg = pkgs.nimrod-portal; };

  nimrod-portal-maint = makeMaintContainer {
    name = "${imagePrefix}/nimrod-portal-maint";
    tag  = "1.0.0";
    text = "Nimrod Portal";
  };

  ipp_1_1 = makeStaticServeContainer { pkg = pkgs.ipp_1_1; };

  ipp-maint = makeMaintContainer {
    name = "${imagePrefix}/ipp-maint";
    tag  = "1.0.0";
    text = "IMB Portal";
  };

  darkhttpd = makeStaticServeContainer {
    name       = "${imagePrefix}/${pkgs.darkhttpd.pname}";
    tag        = pkgs.darkhttpd.version;
    staticPath = "/data";
    noListing  = false;
  };

  keycloak-rcc = callPackage ./keycloak-rcc { };
}
