{ system ? builtins.currentSystem }:
let
  pkgs = import <nixpkgs> { inherit system; };

  callPackage = pkgs.lib.callPackageWith (pkgs // self);

  self = {
    nimrod-portal-backend = callPackage ./pkgs/nimrod-portal-backend { jre = pkgs.openjdk11; };

    portal-client = callPackage ./pkgs/portal-client { jre = pkgs.openjdk11; };

    nimrodg-agent = callPackage ./pkgs/nimrodg-agent { };
  };
in
self
