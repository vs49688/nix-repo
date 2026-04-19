{ lib
, callPackage
, symlinkJoin
, makeBinaryWrapper
}:

let
  engine = callPackage ./engine.nix { };

  sdks = callPackage ./hlsdk.nix { };

  all-games = callPackage ./gamedir.nix {
    inherit sdks;
  };

  buildXash = { engine, games }: symlinkJoin {
    name = "xash3d-fwgs";
    paths = [
      engine
    ] ++ games ++ lib.optionals (!engine.dedicatedOnly) [
      (callPackage ./desktop.nix { inherit engine games; })
    ];

    nativeBuildInputs = [
      makeBinaryWrapper
    ];

    postBuild = ''
      rm $out/bin/xash

      makeWrapper ${engine}/bin/xash $out/bin/.xash-wrapped \
        --prefix LD_LIBRARY_PATH : $out/lib/xash3d \
        --set XASH3D_RODIR $out/lib/xash3d \
        --set XASH3D_EXTRAS_PAK1 $out/share/xash3d/valve/extras.pk3

      substitute ${./launch.sh} $out/bin/xash \
        --subst-var out \
        --subst-var-by xash3d $out/bin/.xash-wrapped

      chmod +x $out/bin/xash

      patchShebangs $out/bin/xash
    '' + (lib.optionalString (!engine.dedicatedOnly) ''
      rm $out/bin/xash3d

      makeWrapper ${engine}/bin/xash3d $out/bin/.xash3d-wrapped \
        --prefix LD_LIBRARY_PATH : $out/lib/xash3d \
        --set XASH3D_RODIR $out/lib/xash3d \
        --set XASH3D_EXTRAS_PAK1 $out/share/xash3d/valve/extras.pk3

      substitute ${./launch.sh} $out/bin/xash3d \
        --subst-var out \
        --subst-var-by xash3d $out/bin/.xash3d-wrapped

      chmod +x $out/bin/xash3d

      patchShebangs $out/bin/xash3d
    '');

    passthru = {
      inherit games engine;

      dedicated = buildXash {
        inherit games;

        engine = engine.override {
          dedicatedOnly = true;
        };
      };
    };
  };
in {
  inherit engine sdks buildXash;

  dedicated = engine.override { dedicatedOnly = true; };

  games = all-games;

  mods = {
    metamod = callPackage ./mods/metamod { };
    jk_botti = callPackage ./mods/jk_botti { };
  };

  withGames = f: let packages = f all-games; in buildXash {
    inherit engine;

    games = packages;
  };
}
