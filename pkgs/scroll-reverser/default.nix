{ lib, stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "scroll-reverser";
  version = "1.8.2";

  src = fetchzip {
    stripRoot = false;
    url = "https://github.com/pilotmoon/Scroll-Reverser/releases/download/v${version}/ScrollReverser-${version}.zip";
    sha256 = "sha256-eDkDeXImcRnwt8zTAKBLPFzuu7HQ8RjG0EcxkZ5SEUw=";
  };

  installPhase = ''
    mkdir -p $out/Applications
    mv "Scroll Reverser.app" $out/Applications
  '';

  meta = with lib; {
    description = "Per-device scrolling prefs on macOS";
    homepage = "https://pilotmoon.com/scrollreverser/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = platforms.darwin;
    maintainers = with maintainers; [ zane ];
    license = licenses.asl20;
  };
}

