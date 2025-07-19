{ asFlake ? false }:
(self: super: (({
  aaxm4bfix = super.callPackage ./pkgs/aaxm4bfix { };

  awesfx = super.callPackage ./pkgs/awesfx { };

  crocutils = super.callPackage ./pkgs/crocutils { };

  croc-lotg = super.callPackage ./pkgs/croc-lotg { };

  extract-drs = super.callPackage ./pkgs/extract-drs { };

  extract-glb = super.callPackage ./pkgs/extract-glb { };

  pimidid = super.callPackage ./pkgs/pimidid { };

  jdownloader = super.callPackage ./pkgs/jdownloader {
    ##
    # Needs to be built with max 11:
    #   [javac] error: Source option 6 is no longer supported. Use 7 or later.
    #   [javac] error: Target option 6 is no longer supported. Use 7 or later.
    ##
    jdk = super.jdk11;
  };

  mailpump = super.callPackage ./pkgs/mailpump { };

  mangostwo-server = super.callPackage ./pkgs/mangostwo-server { };

  mangostwo-database = super.callPackage ./pkgs/mangostwo-database { };

  azerothcore = super.callPackage ./pkgs/azerothcore { };

  zane-scripts = super.callPackages ./pkgs/zane-scripts { };

  offzip = super.callPackage ./pkgs/offzip { };

  _010editor = super.callPackage ./pkgs/010editor { };

  vgmtrans = super.libsForQt5.callPackage ./pkgs/vgmtrans { };

  raftools = super.callPackage ./pkgs/raftools { };

  unifi-backup-decrypt = super.callPackage ./pkgs/unifi-backup-decrypt { };

  hg659-voip-password = super.callPackage ./pkgs/hg659-voip-password {};

  solar2 = super.callPackage ./pkgs/solar2 { };

  supermeatboy = super.callPackage ./pkgs/supermeatboy { };

  xash3d-fwgs = super.callPackage ./pkgs/xash3d-fwgs { };

  xash3d-sdks = super.callPackage ./pkgs/xash3d-fwgs/hlsdk.nix { };

  xash3d-games = self.callPackage ./pkgs/xash3d-fwgs/gamedir.nix { };

  xash3d-fwgs-full = self.xash3d-fwgs.withGames (g: [
    g.valve g.valve_hd
    g.bshift g.bshift_hd
    g.dmc
    g.gearbox g.gearbox_hd
  ]);

  jack-editor = super.libsForQt5.callPackage ./pkgs/jack-editor { };

  rom-parser = super.callPackage ./pkgs/rom-parser { };

  xboomer = super.callPackage ./pkgs/xboomer { };

  redbean = super.callPackage ./pkgs/redbean { };

  umskt = super.callPackage ./pkgs/umskt { };

  gogextract = super.python3Packages.callPackage ./pkgs/gogextract { };

  gogLinuxInstaller = self.callPackage ({ runCommand, gogextract }: { src }: runCommand "${src.name}-data.zip" {} ''
    ${gogextract}/bin/gogextract ${src} .
    mv data.zip $out
    # LANG=en_US.UTF-8 ''${unzip}/bin/unzip -qq -d $out data.zip
  '') {};

  mingw-w64-cc = super.callPackage ./pkgs/mingwcc { mingwPkgs = super.pkgsCross.mingwW64; };

  mingw32-cc = super.callPackage ./pkgs/mingwcc { mingwPkgs = super.pkgsCross.mingw32; };

  ##
  # NX
  ##
  nsz = super.python3Packages.callPackage ./pkgs/nsz { };

  nstool = super.callPackage ./pkgs/nstool { };

  dedbae = super.callPackage ./pkgs/dedbae { };
}) // (super.lib.optionalAttrs (!asFlake) {
  navidrome-mbz = throw "navidrome-mbz has been removed, use navidrome instead";

  linearmouse-bin = throw "linearmouse-bin has been removed, use nix-darwin with Brew";

  scroll-reverser-bin = throw "scroll-reverser-bin has been removed, use nix-darwin with Brew";

  hammerspoon-bin = throw "hammerspoon-bin has been removed, use nix-darwin with Brew";
}) // (super.lib.optionalAttrs (super.stdenv.targetPlatform.isx86 && super.stdenv.targetPlatform.isLinux) {
  x3-terran-war-pack = super.pkgsi686Linux.callPackage ./pkgs/x3-terran-war-pack {
    inherit (self) gogLinuxInstaller;
  };
})))
