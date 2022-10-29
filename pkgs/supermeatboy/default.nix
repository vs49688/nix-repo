{ stdenv, lib, requireFile, unzip, autoPatchelfHook
, makeDesktopItem, copyDesktopItems
, SDL2, openalSoft
}:
stdenv.mkDerivation rec {
  pname = "supermeatboy";
  version = "11112013";

  src = (requireFile {
    message = ''
      Please prefetch "supermeatboy-linux-11112013-bin" from Humble Bundle.
    '';
    name   = "supermeatboy-linux-11112013-bin";
    sha256 = "sha256-bCZcPsGh0Rq3BTiE/VgF8+PDtO4jR7yL6Egc/HgHF4w=";
  }).overrideAttrs(old: { allowSubstitutes = true; });

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    SDL2
    openalSoft
  ];

  unpackPhase = ''
    runHook preUnpack

    unzip -u $src || true

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/{supermeatboy,pixmaps}}

    rm -rf data/SuperMeatBoy data/x86
    rm -f data/amd64/{libopenal.so.1,libSDL2-2.0.so.0}
    cp -R data/* $out/share/supermeatboy

    ln -s $out/share/supermeatboy/amd64/SuperMeatBoy $out/bin/SuperMeatBoy
    ln -s $out/share/supermeatboy/supermeatboy.png $out/share/pixmaps/${pname}.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name        = pname;
      exec        = "SuperMeatBoy";
      icon        = pname;
      comment     = "Super Meat Boy";
      desktopName = "Super Meat Boy";
      categories  = [ "Game" ];
    })
  ];

  meta = with lib; {
    description = "Super Meat Boy";
    homepage    = "http://supermeatboy.com/";
    platforms   = [ "x86_64-linux" ];
    license     = licenses.unfree;
    maintainers = with maintainers; [ zane ];
  };
}
