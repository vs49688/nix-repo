{ stdenv, lib, fetchurl, makeWrapper, jdk, makeDesktopItem, copyDesktopItems }:
let
  description = "A viewer/extraction toolkit for League of Legends";
in
stdenv.mkDerivation rec {
  pname = "raftools";
  version = "0.6.0";

  src = fetchurl {
    url    = "https://github.com/vs49688/RAFTools/releases/download/v${version}/RAFTools.jar";
    sha256 = "1cinyxafvjw26sxrmn63w87c6pf01cdg7sy97l1dc2akjjmbk1y6";
  };

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper copyDesktopItems ];

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

    cp ${./icon256.png} $out/share/pixmaps/raftools.png

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
