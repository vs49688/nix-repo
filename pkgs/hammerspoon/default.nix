{ lib, stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "hammerspoon";
  version = "0.9.97";

  src = fetchzip {
    stripRoot = false;
    url = "https://github.com/Hammerspoon/hammerspoon/releases/download/${version}/Hammerspoon-${version}.zip";
    sha256 = "sha256-z6xkJRUHCm1+CL8ZBslqZ7DUntGK+vSBDa821uqjeiQ=";
  };

  installPhase = ''
    mkdir -p $out/Applications
    mv "Hammerspoon.app" $out/Applications
  '';

  meta = with lib; {
    description = "Staggeringly powerful macOS desktop automation with Lua";
    homepage = "https://www.hammerspoon.org/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = platforms.darwin;
    maintainers = with maintainers; [ zane ];
    license = licenses.mit;
  };
}

