{ lib, stdenv, fetchurl, undmg }:

stdenv.mkDerivation rec {
  pname = "linearmouse";
  version = "0.6.1";

  src = fetchurl {
    url = "https://github.com/linearmouse/linearmouse/releases/download/v${version}/LinearMouse.dmg";
    sha256 = "sha256-acE3RA46Bsr9sRB1o8crrbXpRGEjHG1v/8/GomU6d9U=";
  };

  sourceRoot = "LinearMouse.app";

  nativeBuildInputs = [ undmg ];

  installPhase = ''
    mkdir -p $out/Applications/LinearMouse.app
    cp -R . $out/Applications/LinearMouse.app
  '';

  meta = with lib; {
    description = "The mouse and trackpad utility for Mac";
    homepage = "https://linearmouse.app/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = platforms.darwin;
    maintainers = with maintainers; [ zane ];
    license = licenses.mit;
  };
}

