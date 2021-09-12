{ lib }: let
  callPackage = lib.callPackage;
in
{
  mangostwo-realmd = callPackage ./mangostwo-realmd { };
}
