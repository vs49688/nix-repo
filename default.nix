{ system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
}:
let
  lib = pkgs.lib // {
    callPackage = pkgs.lib.callPackageWith (pkgs // self // { inherit lib; });
    callPackages = pkgs.lib.callPackagesWith (pkgs // self // { inherit lib; });
  };

  overlay = import ./overlay.nix;

  self = {
    inherit lib overlay;
    callPackage = lib.callPackage;
    callPackages = lib.callPackages;
  } // (overlay self pkgs) // {
    pkgsStatic = pkgs.pkgsStatic // rec {
      callPackage = pkgs.lib.callPackageWith (pkgs.pkgsStatic // self.pkgsStatic);
      callPackages = pkgs.lib.callPackagesWith (pkgs.pkgsStatic // self.pkgsStatic);
    };

    pkgs = pkgs // self;

    containers = import ./containers {
      inherit lib;

      pkgs = self.pkgs;
      imagePrefix = "ghcr.io/vs49688";
    };

    hpc = import ./hpc {
      inherit lib;
      pkgs = self.pkgs;
    };
  };
in self
