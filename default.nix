{ system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
}:
let
  lib = pkgs.lib // {
    callPackage = pkgs.lib.callPackageWith (pkgs // self // { inherit lib; });
    callPackages = pkgs.lib.callPackagesWith (pkgs // self // { inherit lib; });
  };

  self = {
    inherit lib;
    callPackage = lib.callPackage;
    callPackages = lib.callPackages;
  } // ((import ./overlay.nix) self pkgs) // {
    pkgsStatic = pkgs.pkgsStatic // rec {
      callPackage = pkgs.lib.callPackageWith (pkgs.pkgsStatic // self.pkgsStatic);
      callPackages = pkgs.lib.callPackagesWith (pkgs.pkgsStatic // self.pkgsStatic);

      tini = callPackage ./pkgs/tini { cmake = pkgs.cmake; };
    };

    pkgs = pkgs // self;

    containers = import ./containers {
      inherit lib;

      pkgs = self.pkgs;
    };
  };
in self
