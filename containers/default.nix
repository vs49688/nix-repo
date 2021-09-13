{ lib, imagePrefix, pkgs }: let
  callPackage = lib.callPackageWith (pkgs // { inherit imagePrefix; });

  makeStaticServeContainer = a@{ pkg ? null, ... }: let
    args = {
      darkhttpd  = pkgs.pkgsStatic.darkhttpd;
    } // lib.optionalAttrs (pkg != null) {
      name       = "${imagePrefix}/${pkg.pname}";
      tag        = pkg.version;
      staticPath = "${pkg}";
    } // a;
  in callPackage ./static-serve-base args;
in rec {
  inherit imagePrefix;

  mangostwo-realmd = callPackage ./mangostwo-realmd { };
  mangostwo-mangosd = callPackage ./mangostwo-mangosd { };
}
