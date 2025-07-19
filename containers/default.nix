{ lib, imagePrefix, pkgs }: let
  callPackage = lib.callPackageWith (pkgs // { inherit imagePrefix; });
in {
  inherit imagePrefix;

  mangostwo-realmd = callPackage ./mangostwo-realmd { };
  mangostwo-mangosd = callPackage ./mangostwo-mangosd { };

  navidrome = callPackage ./navidrome { };
}
