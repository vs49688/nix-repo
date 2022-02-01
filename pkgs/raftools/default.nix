{ stdenv, lib, fetchurl, makeWrapper, unzip, jdk, makeDesktopItem, copyDesktopItems }:
let
  description = "A viewer/extraction toolkit for League of Legends";
in
stdenv.mkDerivation rec {
  pname = "raftools";
  version = "0.6.1";

  src = fetchurl {
    url    = "https://github.com/vs49688/RAFTools/releases/download/v${version}/raftools-${version}.jar";
    sha256 = "15ndg544h8rd5s2jc31sjqfrg8x20vjn33m08dj5zj5lri105vy1";
  };

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ unzip makeWrapper copyDesktopItems ];

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      comment = description;
      desktopName = "RAFTools";
      categories = "Utility;";
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/{pixmaps,raftools}}
    cp $src $out/share/raftools/$(stripHash ${src})

    makeWrapper ${jdk}/bin/java $out/bin/raftools \
      --add-flags "-jar $out/share/raftools/$(stripHash ${src})"

    unzip -j $src net/vs49688/rafview/gui/icon256.png
    cp icon256.png $out/share/pixmaps/raftools.png

    runHook postInstall
  '';

  meta = with lib; {
    inherit description;
    homepage = "https://github.com/vs49688/RAFTools";
    platforms = platforms.all;
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ zane ];
  };
}
