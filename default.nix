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
  } // (import ./overlay.nix) self pkgs;
in
{
  pkgs = pkgs // self;

  containers = lib.callPackages ./containers { };
} // self
