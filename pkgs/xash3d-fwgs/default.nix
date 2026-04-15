{ stdenv
, lib
, callPackage
, fetchFromGitHub
, python3
, wafHook
, pkg-config
, cmake
, SDL2
, libX11
, libogg
, libvorbis
, libopus
, opusfile
, freetype
, fontconfig
, makeWrapper
, makeDesktopItem
, copyDesktopItems
, imagemagick
}:

let
  xash3d-sdks = callPackage ./hlsdk.nix { };

  xash3d-games = callPackage ./gamedir.nix {
    sdks = xash3d-sdks;
  };

  buildXash = games: let
    gamesWithDesktopEntries = builtins.filter (g: g.gameName != null) games;
  in stdenv.mkDerivation rec {
    pname = "xash3d-fwgs";
    version = "unstable-2026-04-13-0";

    src = fetchFromGitHub {
      owner = "FWGS";
      repo  = pname;
      rev = "84b7b5803bed19651d5fa8873225126ffd1ba9d1";
      sha256 = "sha256-ojLLKJcS1og2kvrLAnpzg7S4RxX4eO/l9PZKn2R+WfQ=";

      fetchSubmodules = true;
    };

    nativeBuildInputs = [
      python3
      wafHook
      pkg-config
      makeWrapper
      copyDesktopItems
    ];

    buildInputs = [
      SDL2
      libX11
      libogg
      libvorbis
      libopus
      opusfile
      freetype
      fontconfig
    ];

    # Set the Epoch to 1980; otherwise the Python wheel/zip code
    # gets very angry
    preConfigure = ''
      find . -type f | while read file; do
        touch -d @315532800 $file;
      done
    '';

    wafConfigureFlags = [
      # "--use-sdl3" # SDL3 support is shoddy
      "--build-type=humanrights"
      "--64bits"
      "--enable-all-renderers"
      "--enable-packaging"
      # "--enable-lto" # causes filesystem linker errors
      "--enable-poly-opt"
      "--enable-openmp"
      "--enable-packaging"

      "--enable-utils"
      "--enable-xar"
    ];

    dontUseWafInstall = false;

    wafInstallFlags = [
      "--destdir=/"
    ];

    postInstall = ''
      mkdir -p $out/share/pixmaps

      mv $out/bin/xash3d $out/bin/.xash3d-wrapped
      substitute ${./launch.sh} $out/bin/xash3d --subst-var out

      chmod +x $out/bin/xash3d
    '' + (builtins.concatStringsSep "" (builtins.map (g: ''
      ln -s ${g} $out/lib/xash3d/${g.gamedir}
    '') games)) + (builtins.concatStringsSep "" (builtins.map (g: ''
      ${imagemagick}/bin/magick convert ${g}/game.tga $out/share/pixmaps/xash3d-${g.gamedir}.png
    '') gamesWithDesktopEntries));

    passthru = {
      inherit games;

      withGames = f: let packages = f xash3d-games; in buildXash packages;
    };

    desktopItems = (builtins.map (g: makeDesktopItem {
      name = "xash3d-${g.gamedir}";
      exec = "xash3d -game ${g.gamedir}";
      icon = "xash3d-${g.gamedir}";
      comment = g.gameName;
      desktopName = g.gameName;
      categories = [ "Game" ];
    }) gamesWithDesktopEntries) ++ (builtins.map (g: makeDesktopItem {
      name = "xash3d-${g.gamedir}-console";
      exec = "xash3d -game ${g.gamedir} -console";
      icon = "xash3d-${g.gamedir}";
      comment = "${g.gameName} (Console)";
      desktopName = "${g.gameName} (Console)";
      categories = [ "Game" ];
    }) gamesWithDesktopEntries);

    meta = with lib; {
      description = "Xash3D FWGS engine";
      homepage = "https://github.com/FWGS/xash3d-fwgs";
      platforms = [ "x86_64-linux" "aarch64-linux" ];
      maintainers = with maintainers; [ zane ];
    };
  };
in buildXash []
