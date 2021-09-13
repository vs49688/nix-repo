{ lib, imagePrefix, pkgs }: let
  callPackage = lib.callPackageWith (pkgs // { inherit imagePrefix; });
in rec {
  inherit imagePrefix;

  mangostwo-realmd = callPackage ./mangostwo-realmd { };
  mangostwo-mangosd = callPackage ./mangostwo-mangosd { };
}
