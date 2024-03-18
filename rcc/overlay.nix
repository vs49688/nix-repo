##
# Old RCC packages, for posterity.
##
final: prev: {
  nimrod-portal-backend = prev.callPackage ./nimrod-portal-backend {
    jre = prev.openjdk11_headless;
  };

  portal-client = prev.callPackage ./portal-client {
    jre = prev.openjdk11_headless;
  };

  # This doesn't have schema validation for the old imb portal
  portal-client_1_0_4 = final.portal-client.overrideAttrs(old: rec {
    version = "1.0.4";
    src = prev.fetchurl {
      url    = "https://github.com/UQ-RCC/portal-client/releases/download/${version}/portal-client-${version}.tar.gz";
      sha256 = "0cdcwjbfixb3b77hqg0jif94q6a6ybp9wnlx8qqv1vnr45vnla1x";
    };
  });

  portal-resource-server = prev.callPackage ./portal-resource-server {
    jre = prev.openjdk8_headless;
  };

  nimrodg-agent = prev.callPackage ./nimrodg-agent { };

  nimrun = prev.callPackage ./nimrun { };

  nimptool-legacy = prev.callPackage ./nimptool-legacy { };

  ims2tif = prev.callPackage ./ims2tif { };

  imsmeta = prev.callPackage ./imsmeta { };

  nimrod-portal = prev.callPackage ./nimrod-portal { };

  ipp_1_1 = prev.callPackage ./ipp { };

  nimrod-embedded = final.callPackage ./nimrod-embedded {
    nimrun = final.pkgsStatic.callPackage ./nimrun { };

    installPrefix = "/sw7/RCC/NimrodG";
    modulePath    = "/sw7/Modules/RCC/local";
  };

  nimrod-embedded-usq = let
    moduleName = "nimrodg";
  in final.callPackage ./nimrod-embedded {
    inherit moduleName;

    modulePath    = "/usr/local/opt/modules";
    installPrefix = "/nonexistant";
    rootDir       = "/usr/local/opt/software/${moduleName}/${final.nimrod-embedded.version}";
  };
}
