{ system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
}:
let
  lib = pkgs.lib // {
    callPackage = pkgs.lib.callPackageWith (pkgs // self);
    callPackages = pkgs.lib.callPackagesWith (pkgs // self);
  };

  self = {
    inherit lib;
  };
in
{ pkgs = self; } // self
