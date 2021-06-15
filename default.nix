{ system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
}:
let
  callPackage = pkgs.lib.callPackageWith (pkgs // self);

  self = rec {

    nimrod-portal-backend = callPackage ./pkgs/nimrod-portal-backend { jre = pkgs.openjdk11_headless; };

    portal-client = callPackage ./pkgs/portal-client { jre = pkgs.openjdk11_headless; };

    # This doesn't have schema validation for the old imb portal
    portal-client_1_0_4 = portal-client.overrideDerivation(old: rec {
      version = "1.0.4";
      name    = "${old.pname}-${version}";
      src = pkgs.fetchurl {
        url    = "https://github.com/UQ-RCC/portal-client/releases/download/${version}/portal-client-${version}.tar.gz";
        sha256 = "0cdcwjbfixb3b77hqg0jif94q6a6ybp9wnlx8qqv1vnr45vnla1x";
      };
    });

    portal-resource-server = callPackage ./pkgs/portal-resource-server { jre = pkgs.openjdk8_headless; };

    nimrodg-agent = callPackage ./pkgs/nimrodg-agent { };

    nimrun = callPackage ./pkgs/nimrun { };

    nimptool-legacy = callPackage ./pkgs/nimptool-legacy { };

    ims2tif = callPackage ./pkgs/ims2tif { };

    imsmeta = callPackage ./pkgs/imsmeta { };

    nimrod-portal = callPackage ./pkgs/nimrod-portal { };

    lib = pkgs.lib // rec {
      makeStaticServeContainer = { pkg }: callPackage ./containers/static-serve-base {
        inherit pkg;

        tini      = pkgsStatic.tini;
        darkhttpd = pkgsStatic.darkhttpd;
      };
    };

    containers = {
      nimrod-portal-backend = callPackage ./containers/spring-base {
        pkg = nimrod-portal-backend;
      };

      portal-client = callPackage ./containers/spring-base {
        pkg  = portal-client;
        args = ["run"];
      };

      portal-client_1_0_4 = callPackage ./containers/spring-base {
        pkg = portal-client_1_0_4;
      };

      portal-resource-server = callPackage ./containers/spring-base {
        pkg = portal-resource-server;
      };

      nimrod-portal = lib.makeStaticServeContainer { pkg = nimrod-portal; };
    };

    hpc = rec {
      nimrod-embedded = callPackage ./hpc/nimrod-embedded {
        nimrun        = pkgsStatic.nimrun;
        installPrefix = "/sw7/RCC/NimrodG";
        modulePath    = "/sw7/Modules/RCC/local";
      };

      nimrod-embedded-usq = nimrod-embedded.override rec {
        moduleName    = "nimrodg";
        modulePath    = "/usr/local/opt/modules";
        installPrefix = "/nonexistant";
        rootDir       = "/usr/local/opt/software/${moduleName}/${nimrod-embedded.version}";
      };
    };

    ##
    # NB: Not sure if this is the best way to do this.
    #
    # Also note that static cmake is completely broken.
    ##
    pkgsStatic = rec {
      callPackage = pkgs.lib.callPackageWith (pkgs.pkgsStatic // self.pkgsStatic);

      nimrun = callPackage ./pkgs/nimrun { cmake = pkgs.cmake; };

      # No static build for this, hdf5 is being hdf5 again...
      #ims2tif = callPackage ./pkgs/ims2tif { cmake = pkgs.cmake; };

      imsmeta = callPackage ./pkgs/imsmeta { cmake = pkgs.cmake; };

      # Upstream tini depends directly on glibc
      tini = callPackage ./pkgs/tini { cmake = pkgs.cmake; };

      darkhttpd = callPackage ./pkgs/darkhttpd { };
    };
  };
in
self
