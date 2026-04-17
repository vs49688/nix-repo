{ stdenvNoCC
, engine
, games
, makeDesktopItem
, copyDesktopItems
, imagemagick
}: let
  gamesWithDesktopEntries = builtins.filter (g: g.gameName != null) games;
in
stdenvNoCC.mkDerivation(finalAttrs: {
  inherit (engine) version;

  pname = "xash3d-fwgs-desktop-entries";

  dontUnpack = true;

  nativeBuildInputs = [
    copyDesktopItems
  ];

  postInstall = ''
    mkdir -p $out/share/pixmaps
  '' + (builtins.concatStringsSep "" (builtins.map (g: ''
    ${imagemagick}/bin/magick convert ${g}/${g.iconPath} $out/share/pixmaps/xash3d-${g.gamedir}.png
  '') gamesWithDesktopEntries));

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
})
