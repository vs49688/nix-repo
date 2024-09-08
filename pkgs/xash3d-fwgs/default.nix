{ stdenv, lib, fetchFromGitHub, python3, wafHook, pkg-config, cmake
, SDL2, libopus, freetype, fontconfig, makeWrapper
, makeDesktopItem, copyDesktopItems
, imagemagick
, xash3d-games
}:

let
  buildXash = games: let
    gamesWithDesktopEntries = builtins.filter (g: g.gameName != null) games;
  in stdenv.mkDerivation rec {
    pname = "xash3d-fwgs";
    version = "unstable-2024-09-05";

    src = fetchFromGitHub {
      owner = "FWGS";
      repo  = pname;
      rev = "178602ea1fa85f700a2a5873d983162b42b3e9f4";
      sha256 = "sha256-IVLuZFxJJ+hO/XrdBcEuBb6Nj5SeInFQynFOzwfSq3Q=";

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
      libopus
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
      "--build-type=humanrights"
      "--64bits"
      "--enable-all-renderers"
      "--enable-packaging"
      # "--enable-lto" # causes filesystem linker errors
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
