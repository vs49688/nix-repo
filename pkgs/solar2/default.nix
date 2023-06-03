{ stdenv, lib, requireFile, autoPatchelfHook, makeWrapper
, makeDesktopItem, copyDesktopItems
, curl, zlib, lttng-ust
, icu58, SDL2, openssl_1_1
, alsa-lib, libpulseaudio
}:
let
  # This is fine for a game.
  xssl = openssl_1_1.overrideAttrs(old: {
    meta = old.meta // { insecure = false; knownVulnerabilities = []; };
  });
in
stdenv.mkDerivation rec {
  pname   = "solar2";
  version = "1.25";

  src = (requireFile {
    message = ''
      Please prefetch "Solar2_v1.25_amd64.tar" from Humble Bundle.
    '';
    name   = "Solar2_v1.25_amd64.tar";
    sha256 = "sha256-cHQVjUQG4C3YUab7i7MzWwE/+pZBrts8HyU/6JMpnAY=";
  }).overrideAttrs(old: { allowSubstitutes = true; });

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    curl
    #lttng-ust
  ];

  autoPatchelfIgnoreMissingDeps = true;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/{solar2,pixmaps}}
    mv * $out/share/solar2

    rm -f $out/share/solar2/libSDL2-2.0.so.0

    makeWrapper $out/share/solar2/Solar2 $out/bin/Solar2 \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ icu58 SDL2 xssl alsa-lib libpulseaudio ]}:/run/opengl-driver/lib

    ln -s $out/share/solar2/solar2icon_512x512_transparent.png $out/share/pixmaps/${pname}.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name        = pname;
      exec        = "Solar2";
      icon        = pname;
      comment     = "Solar 2";
      desktopName = "Solar 2";
      categories  = [ "Game" ];
    })
  ];

  meta = with lib; {
    description = "Solar 2";
    homepage    = "http://murudai.com/solar/";
    platforms   = [ "x86_64-linux" ];
    license     = licenses.unfree;
    maintainers = with maintainers; [ zane ];
  };
}
