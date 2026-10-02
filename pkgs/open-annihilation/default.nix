{ stdenv
, lib
, fetchFromGitHub
, zlib
, cmake
, sdl3
, ffmpeg-headless
, makeDesktopItem
, copyDesktopItems
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "open-annihilation";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "open-annihilation";
    repo = "open-annihilation";
    rev = "v${finalAttrs.version}";
    hash = "sha256-4Eazi/khWg7gx/0lXeAi3smTlAxN8v/IKD8xsrPZ/n8=";
  };

  nativeBuildInputs = [
    cmake
    copyDesktopItems
  ];

  buildInputs = [
    zlib
    sdl3
    ffmpeg-headless
  ];

  buildFlags = [
    "oa-game"
    "oa-tool"
  ];

  # There's no CMake install configured
  installPhase = ''
    runHook preInstall

    install -Dm755 oa-tool $out/bin/oa-tool
    install -Dm755 open-annihilation $out/bin/open-annihilation
    install -Dm644 ${finalAttrs.src}/branding/open-annihilation-256.png $out/share/icons/hicolor/256x256/apps/open-annihilation.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "open-annihilation";
      exec = "open-annihilation";
      icon = "open-annihilation";
      desktopName = "Open Annihilation";
      categories = [ "Game" "StrategyGame" ];
      comment = finalAttrs.meta.description;
    })
  ];

  meta = with lib; {
    description = "Open Source port of the Total Annihilation & TA: Kingdoms engines";
    homepage = "https://coreprime.net/";
    platforms = platforms.linux; # Darwin untested
    license = licenses.gpl3Plus;
  };
})
