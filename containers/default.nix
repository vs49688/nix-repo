{ lib, pkgs }: let
  callPackage = lib.callPackageWith pkgs;
in {
  mangostwo-realmd = callPackage ./mangostwo-realmd { };
  mangostwo-mangosd = callPackage ./mangostwo-mangosd { };
}
