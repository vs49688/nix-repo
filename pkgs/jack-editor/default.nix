{ stdenv
, lib
, requireFile
, fetchFromGitHub
, makeWrapper
, autoPatchelfHook
, makeDesktopItem
, copyDesktopItems
, patchelf
, nas
, glib
, icu
, libxml2
, libpng12
, libX11
, libXext
, libXfixes
, libXrender
, libXcursor
, libXft
, libXt
, libICE
, libSM
, libGL
}:

let
  # We need an _ancient_ version of icu.
  icu48 = stdenv.mkDerivation(finalAttrs: {
    pname = "icu";
    version = "48.1.1";

    src = fetchFromGitHub {
      owner = "unicode-org";
      repo = "icu";
      rev = "icu-release-4-8-1-1";
      hash = "sha256-zM/IlpdjLUOD5rsww4YCBTAqLbdcyavLtEPmd2rLC5g=";
    };

    sourceRoot = "source/source";

    postPatch = ''
      sed -i 's/position > 0/position != NULL/g' i18n/uspoof.cpp
    '';
  });

  description = "A brand new level editor for games with a quake-style BSP architecture";
in
stdenv.mkDerivation(finalAttrs: {
  pname = "jack-editor";
  version = "1.1.3773";

  src = (requireFile {
    message = ''
      Please prefecth "jack_113773_linux_x64.run" from https://jack.hlfx.ru/en/download.html into the Nix store.
    '';
    name = "jack_113773_linux_x64.run";
    sha256 = "sha256-GdaOjUb5T7ySXFUCCesNP192YDn3CKaqOvf0YNeayWs=";
  }).overrideAttrs(old: { allowSubstitutes = true; });

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
    copyDesktopItems
  ];

  buildInputs = [
    stdenv.cc.libc
    stdenv.cc.cc.lib
    nas
    glib
    icu48
    libxml2
    libpng12
    libX11
    libXext
    libXfixes
    libXrender
    libXcursor
    libXft
    libXt
    libICE
    libSM
    libGL
  ];

  installPhase = ''
    runHook preInstall

    sh ${finalAttrs.src} --noexec --target $out/opt/jack

    rm -f $out/opt/jack/Jack.sh $out/opt/jack/install.sh $out/opt/jack/libpng12.so.0

    mkdir -p $out/bin $out/share/pixmaps
    ln $out/opt/jack/Jack $out/bin/Jack
    mv $out/opt/jack/Jack.xpm $out/share/pixmaps/jack-editor.xpm

    runHook postInstall $out/opt/jack/Jack
  '';

  postFixup = ''
    patchelf $out/opt/jack/libQtCore.so.4 \
      --add-needed libicui18n.so.48
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "jack-editor";
      exec = "Jack";
      icon = "jack-editor";
      comment = description;
      desktopName = "J.A.C.K.";
      categories = [ "Game" ];
    })
  ];

  meta = with lib; {
    inherit description;

    homepage = "https://jack.hlfx.ru/en/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
})
