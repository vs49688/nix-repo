{ stdenv
, lib
, requireFile
, gogLinuxInstaller
, unzip
, makeBinaryWrapper
, autoPatchelfHook
, makeDesktopItem
, copyDesktopItems
, zlib
, bzip2
, libjpeg8
, libxml2
, libvorbis
, openal
, SDL2
, gtk2-x11
, pango
}:
stdenv.mkDerivation(finalAttrs: {
	pname = "x3-terran-war-pack";
  version = "3.8.51737";

  src = gogLinuxInstaller {
    src = (requireFile {
      message = ''
        Please prefetch "x3_terran_war_pack_3_8_51737.sh" from GoG into the Nix store.
      '';
      name = "x3_terran_war_pack_3_8_51737.sh";
      hash = "sha256-cTrqS+BB8cziE+lera0fyAlJOw+kv5Z7ulLCQLH/grw=";
    }).overrideAttrs(old: { allowSubstitutes = true; });
  };

  dontUnpack = true;

  nativeBuildInputs = [
    unzip
    makeBinaryWrapper
    autoPatchelfHook
    copyDesktopItems
  ];

  buildInputs = [
    stdenv.cc.libc
    stdenv.cc.cc.lib
    zlib
    bzip2
    # NB: Use the embedded libxml2, text loading breaks with the system one.
    # libxml2
    libjpeg8
    libvorbis
    SDL2
    openal
    gtk2-x11
    pango
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt
    unzip ${finalAttrs.src} -d $out
    mv $out/data/noarch/game $out/opt/x3-terran-war-pack
    rm -rf $out/data $out/meta $out/scripts

    rm -f \
      "$out/opt/x3-terran-war-pack/lib/libz.so.1"          \
      "$out/opt/x3-terran-war-pack/lib/libbz2.so.1.0"      \
      "$out/opt/x3-terran-war-pack/lib/libjpeg.so.8"       \
      "$out/opt/x3-terran-war-pack/lib/libpng12.so.0"      \
      "$out/opt/x3-terran-war-pack/lib/libvorbisfile.so.3" \
      "$out/opt/x3-terran-war-pack/lib/libvorbis.so.0"     \
      "$out/opt/x3-terran-war-pack/lib/libopenal.so.1"     \
      "$out/opt/x3-terran-war-pack/lib/libSDL2-2.0.so.0"

    for i in X3AP_config X3FL_config X3TC_config; do
      makeWrapper "$out/opt/x3-terran-war-pack/$i" "$out/bin/$i" \
        --chdir "$out/opt/x3-terran-war-pack"
    done

    install -Dm644 ${./X3TC.png} $out/share/pixmaps/x3tc.png
    install -Dm644 ${./X3FL.png} $out/share/pixmaps/x3fl.png
    install -Dm644 ${./X3AP.png} $out/share/pixmaps/x3ap.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "x3tc";
      exec = "X3TC_config";
      icon = "x3tc";
      desktopName = "X3: Terran Conflict";
      categories = [ "Game" ];
    })

    (makeDesktopItem {
      name = "x3fl";
      exec = "X3FL_config";
      icon = "x3fl";
      desktopName = "X3: Farnham's Legacy";
      categories = [ "Game" ];
    })

    (makeDesktopItem {
      name = "x3ap";
      exec = "X3AP_config";
      icon = "x3ap";
      desktopName = "X3: Albion Prelude";
      categories = [ "Game" ];
    })
  ];

  meta = with lib; {
    description = "X3: Terran War Pack";
    homepage = "https://www.gog.com/en/game/x3_terran_war_pack";
    platforms = [ "x86_64-linux" "i686-linux" ];
    license = licenses.unfree;
    maintainers = with maintainers; [ zane ];
  };
})
