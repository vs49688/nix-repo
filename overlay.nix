self: super: rec {
  makeStaticServeContainer = a@{ pkg ? null, imagePrefix ? "", ... }: let
    args = {
      darkhttpd  = super.pkgsStatic.darkhttpd;
    } // super.lib.optionalAttrs (pkg != null) {
      name       = if (imagePrefix == "") then pkg.pname else "${imagePrefix}/${pkg.pname}";
      tag        = pkg.version;
      staticPath = "${pkg}";
    } // a;
  in super.callPackage ./containers/static-serve-base args;

  awesfx = super.callPackage ./pkgs/awesfx { };

  crocutils = super.callPackage ./pkgs/crocutils { };

  croc-lotg = super.callPackage ./pkgs/croc-lotg { };

  extract-drs = super.callPackage ./pkgs/extract-drs { };

  extract-glb = super.callPackage ./pkgs/extract-glb { };

  pimidid = super.callPackage ./pkgs/pimidid { };

  jdownloader = super.callPackage ./pkgs/jdownloader {
    ##
    # Needs to be built with max 11:
    #   [javac] error: Source option 6 is no longer supported. Use 7 or later.
    #   [javac] error: Target option 6 is no longer supported. Use 7 or later.
    ##
    jdk = super.jdk11;
  };

  mailpump = super.callPackage ./pkgs/mailpump { };

  mangostwo-server = super.callPackage ./pkgs/mangostwo-server { };

  mangostwo-database = super.callPackage ./pkgs/mangostwo-database { };

  zane-scripts = super.callPackages ./pkgs/zane-scripts { };

  offzip = super.callPackage ./pkgs/offzip { };

  _010editor = super.callPackage ./pkgs/010editor { };

  vgmtrans = super.libsForQt5.callPackage ./pkgs/vgmtrans { };

  revive = super.callPackage ./pkgs/revive { };

  raftools = super.callPackage ./pkgs/raftools { };

  unifi-backup-decrypt = super.callPackage ./pkgs/unifi-backup-decrypt { };

  kafkactl = super.callPackage ./pkgs/kafkactl { };

  navidrome-mbz = super.callPackage ./pkgs/navidrome-mbz {
    nodejs = super.nodejs-18_x;
  };

  hg659-voip-password = super.callPackage ./pkgs/hg659-voip-password {};

  solar2 = super.callPackage ./pkgs/solar2 { };

  supermeatboy = super.callPackage ./pkgs/supermeatboy { };

  xash3d-fwgs = super.callPackage ./pkgs/xash3d-fwgs { };

  xash3d-sdks = super.callPackage ./pkgs/xash3d-fwgs/hlsdk.nix { };

  xash3d-games = self.callPackage ./pkgs/xash3d-fwgs/gamedir.nix { };

  xash3d-fwgs-full = self.xash3d-fwgs.withGames (g: [
    g.valve g.valve_hd
    g.bshift g.bshift_hd
    g.dmc
    g.gearbox g.gearbox_hd
  ]);

  mongodb_3_6-bin = super.callPackage ./pkgs/mongodb-bin {
    version = "3.6.23";

    src = super.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-3.6.23.tgz";
      sha256 = "sha256-woT7k+A5WVyQFwzUuo8ruU/8YVMn9b9QWsWy/j9qW+U=";
    };
  };

  rom-parser = super.callPackage ./pkgs/rom-parser { };

  ##
  # For macOS
  ##
  linearmouse-bin = super.callPackage ./pkgs/linearmouse { };

  scroll-reverser-bin = super.callPackage ./pkgs/scroll-reverser { };

  hammerspoon-bin = super.callPackage ./pkgs/hammerspoon { };

  ##
  # Old RCC packages, for posterity.
  ##

  nimrod-portal-backend = super.callPackage ./pkgs/nimrod-portal-backend {
    jre = super.openjdk11_headless;
  };

  portal-client = super.callPackage ./pkgs/portal-client {
    jre = super.openjdk11_headless;
  };

  # This doesn't have schema validation for the old imb portal
  portal-client_1_0_4 = self.portal-client.overrideDerivation(old: rec {
    version = "1.0.4";
    name    = "${old.pname}-${version}";
    src = super.fetchurl {
      url    = "https://github.com/UQ-RCC/portal-client/releases/download/${version}/portal-client-${version}.tar.gz";
      sha256 = "0cdcwjbfixb3b77hqg0jif94q6a6ybp9wnlx8qqv1vnr45vnla1x";
    };
  });

  portal-resource-server = super.callPackage ./pkgs/portal-resource-server {
    jre = super.openjdk8_headless;
  };

  nimrodg-agent = super.callPackage ./pkgs/nimrodg-agent { };

  nimrun = super.callPackage ./pkgs/nimrun { };

  nimptool-legacy = super.callPackage ./pkgs/nimptool-legacy { };

  ims2tif = super.callPackage ./pkgs/ims2tif { };

  imsmeta = super.callPackage ./pkgs/imsmeta { };

  nimrod-portal = super.callPackage ./pkgs/nimrod-portal { };

  ipp_1_1 = super.callPackage ./pkgs/ipp { };
}
