{ stdenv
, stdenvNoCC
, lib
, fetchFromGitHub
, zlib
, cmake
, sdl3
, freetype
, ffmpeg-headless
, dejavu_fonts
, noto-fonts-cjk-sans-static
, noto-fonts-monochrome-emoji
, python3
, makeDesktopItem
, copyDesktopItems
}:
let
  # The four fonts cmake/OaTextFonts.cmake copies beside the game. Three come
  # from the projects that publish them; NotoSansCJKsc-Bold.otf is published
  # nowhere, being the Simplified Chinese face (index 2) of Noto Sans CJK's
  # Bold collection. Upstream's tools/bootstrap_text_fonts.py extracts it and
  # cuts it down to the common CJK sets; the cut only saves size, so the whole
  # face travels instead.
  textFonts = stdenvNoCC.mkDerivation {
    pname = "open-annihilation-text-fonts";
    version = "2.004";

    nativeBuildInputs = [ (python3.withPackages (ps: [ ps.fonttools ])) ];

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      install -m644 ${dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf $out/
      install -m644 ${dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf $out/
      install -m644 ${noto-fonts-monochrome-emoji}/share/fonts/noto/NotoEmoji.ttf $out/
      python3 - "$out" <<'PY'
      import sys
      from fontTools.ttLib import TTFont
      TTFont(
          "${noto-fonts-cjk-sans-static}/share/fonts/opentype/noto-cjk/NotoSansCJK-Bold.ttc",
          fontNumber=2,
          recalcTimestamp=False,
      ).save(sys.argv[1] + "/NotoSansCJKsc-Bold.otf")
      PY

      runHook postInstall
    '';
  };
in
stdenv.mkDerivation(finalAttrs: {
  pname = "open-annihilation";
  version = "0.7.2";

  src = fetchFromGitHub {
    owner = "open-annihilation";
    repo = "open-annihilation";
    rev = "v${finalAttrs.version}";
    hash = "sha256-kQ3glkQrI2QKqV9vomSBNnmh9ES8nY6KvhDHRjQE7nI=";
  };

  nativeBuildInputs = [
    cmake
    copyDesktopItems
  ];

  buildInputs = [
    zlib
    sdl3
    ffmpeg-headless
    freetype
  ];

  # The fonts cmake/OaTextFonts.cmake copies beside the game.
  cmakeFlags = [
    "-DOA_TEXT_FONTS_DIR=${textFonts}"
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
    # bundled_font_directory() reads the fonts from the executable's folder
    # (src/platform/text-font/src/font_directory.cpp).
    install -Dm644 -t $out/bin/fonts ${textFonts}/*.ttf ${textFonts}/*.otf

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
