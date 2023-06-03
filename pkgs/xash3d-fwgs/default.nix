{ stdenv, lib, fetchFromGitHub, python3, wafHook, pkg-config, cmake
, SDL2, libopus, freetype, fontconfig, makeWrapper
, makeDesktopItem, copyDesktopItems
, imagemagick_light
, xash3d-games
}:

let
  buildXash = games: let
    gamesWithDesktopEntries = builtins.filter (g: g.gameName != null) games;
  in stdenv.mkDerivation rec {
    pname = "xash3d-fwgs";
    version = "unstable-2023-03-02";

    src = fetchFromGitHub {
      owner = "FWGS";
      repo  = pname;
      rev = "f13c28528706aee2b8a86ef58f8d32b3d934d502";
      hash = "sha256-wIYQcrt9sqEspvHt0n0lpQq4Ve11yn4SSPEmyyggANM=";

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

    ##
    # NB: "--enable-lto" causes filesystem linker errors
    ##
    wafConfigureFlags = "--build-type=release --64bits --enable-all-renderers --enable-packaging";

    dontUseWafInstall = false;

    postInstall = ''
      mkdir -p $out/bin $out/share/pixmaps

      substitute ${./launch.sh} $out/bin/xash3d --subst-var out

      chmod +x $out/bin/xash3d
    '' + (builtins.concatStringsSep "" (builtins.map (g: ''
      ln -s ${g} $out/lib/xash3d/${g.gamedir}
    '') games)) + (builtins.concatStringsSep "" (builtins.map (g: ''
      ${imagemagick_light}/bin/convert ${g}/game.tga $out/share/pixmaps/xash3d-${g.gamedir}.png
    '') gamesWithDesktopEntries));

    passthru = {
      inherit games;

      withGames = f: let packages = f xash3d-games; in buildXash packages;
    };

    desktopItems = builtins.map (g: makeDesktopItem {
      name = "xash3d-${g.gamedir}";
      exec = "xash3d -game ${g.gamedir}";
      icon = "xash3d-${g.gamedir}";
      comment = g.gameName;
      desktopName = g.gameName;
      categories = [ "Game" ];
    }) gamesWithDesktopEntries;

    meta = with lib; {
      description = "Xash3D FWGS engine";
      homepage = "https://github.com/FWGS/xash3d-fwgs";
      platforms = [ "x86_64-linux" "aarch64-linux" ];
      maintainers = with maintainers; [ zane ];
    };
  };
in buildXash []
