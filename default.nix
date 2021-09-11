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

    crocutils = lib.callPackage ./pkgs/crocutils { };

    extract-drs = lib.callPackage ./pkgs/extract-drs { };
  };
in
{ pkgs = self; } // self
