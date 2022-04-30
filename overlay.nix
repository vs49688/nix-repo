self: super: rec {
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

  cmdpack = super.callPackages ./pkgs/cmdpack { };

  offzip = super.callPackage ./pkgs/offzip { };

  _010editor = super.callPackage ./pkgs/010editor { };

  vgmtrans = super.libsForQt5.callPackage ./pkgs/vgmtrans { };

  revive = super.callPackage ./pkgs/revive { };

  raftools = super.callPackage ./pkgs/raftools { };

  unifi-backup-decrypt = super.callPackage ./pkgs/unifi-backup-decrypt { };

  kafkactl = super.callPackage ./pkgs/kafkactl { };

  kubefwd = super.callPackage ./pkgs/kubefwd { };

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
