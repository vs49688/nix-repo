{ stdenv
, lib
, fetchFromGitHub
, jdk
, jre ? jdk
, ant
, unoconv
, makeWrapper
, makeDesktopItem
, copyDesktopItems
}:
stdenv.mkDerivation rec {
  pname = "jpsxdec";
  version = "1.05";

  description = "Cross-platform PlayStation 1 audio and video converter";

  src = fetchFromGitHub {
    owner = "m35";
    repo = pname;
    rev = "v${version}";
    sha256 = "0wnfvvcyldf699b08lzlc0gshl7rn09a6q4i7jmr41izlcdszdbz";
  };

  nativeBuildInputs = [ ant jdk unoconv makeWrapper copyDesktopItems ];
  buildInputs = [ jre ];

  patches = [
    ./0001-jpsxdec-hackfix-build-with-newer-JDKs.patch
  ];

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      comment = description;
      desktopName = "jPSXdec";
      categories = "AudioVideo;Utility;";
    })
  ];

  buildPhase = ''
    runHook preBuild

    cd jpsxdec
    mkdir -p _ant/release/doc/
    unoconv -d document -f pdf -o _ant/release/doc/jPSXdec-manual.pdf doc/jPSXdec-manual.odt

    ant release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/pixmaps}
    mv _ant/release $out/jpsxdec

    makeWrapper ${jre}/bin/java $out/bin/jpsxdec \
      --add-flags "-jar $out/jpsxdec/jpsxdec.jar"

    cp ${src}/jpsxdec/src/jpsxdec/gui/icon48.png $out/share/pixmaps/${pname}.png

    runHook postInstall
  '';

  meta = with lib; {
    inherit description;
    homepage = "https://jpsxdec.blogspot.com/";
    platforms = platforms.all;
    license = {
      url = "https://raw.githubusercontent.com/m35/jpsxdec/readme/.github/LICENSE.md";
      free = true;
    };
    maintainers = with maintainers; [ zane ];
  };
}
