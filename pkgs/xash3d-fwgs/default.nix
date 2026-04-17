{ callPackage
, symlinkJoin
, makeBinaryWrapper
}:

let
  engine = callPackage ./engine.nix { };

  sdks = callPackage ./hlsdk.nix { };

  all-games = callPackage ./gamedir.nix {
    inherit sdks;
  };

  buildXash = games: symlinkJoin {
    name = "xash3d-fwgs";
    paths = [
      engine
      (callPackage ./desktop.nix { inherit engine games; })
    ] ++ games;

    nativeBuildInputs = [
      makeBinaryWrapper
    ];

    postBuild = ''
      rm $out/bin/xash3d

      makeWrapper ${engine}/bin/xash3d $out/bin/.xash3d-wrapped \
        --prefix LD_LIBRARY_PATH : $out/lib/xash3d \
        --set XASH3D_RODIR $out/lib/xash3d \
        --set XASH3D_EXTRAS_PAK1 $out/share/xash3d/valve/extras.pk3

      substitute ${./launch.sh} $out/bin/xash3d --subst-var out
      chmod +x $out/bin/xash3d
    '';

    passthru = {
      inherit games engine;
    };
  };
in {
  inherit engine sdks buildXash;

  games = all-games;

  withGames = f: let packages = f all-games; in buildXash packages;
}
