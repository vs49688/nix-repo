{ system ? builtins.currentSystem }:
let
  pkgs = import <nixpkgs> { inherit system; };

  callPackage = pkgs.lib.callPackageWith (pkgs // self);

  self = {
    nimrod-portal-backend = callPackage ./pkgs/nimrod-portal-backend { jre = pkgs.openjdk11; };

    portal-client = callPackage ./pkgs/portal-client { jre = pkgs.openjdk11; };

    nimrodg-agent = callPackage ./pkgs/nimrodg-agent { };

    ims2tif = callPackage ./pkgs/ims2tif { };

    containers = {
      nimrod-portal-backend = callPackage ./containers/nimrod-portal-backend {};

      portal-client = callPackage ./containers/portal-client {};
    };
  };
in
self
