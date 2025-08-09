{ lib, imagePrefix, pkgs }: let
  callPackage = lib.callPackageWith (pkgs // { inherit imagePrefix; });
in {
  inherit imagePrefix;

  mangostwo-realmd = callPackage ./mangostwo-realmd { };
  mangostwo-mangosd = callPackage ./mangostwo-mangosd { };

  navidrome = throw "navidrome container has been removed, use Navidrome >= 0.58 for multiple libraries.";
}
