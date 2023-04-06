{ stdenv, lib, cmake, fetchFromGitHub }:
stdenv.mkDerivation rec {
  pname   = "CrocUtils";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner  = "vs49688";
    repo   = pname;
    rev    = version;
    sha256 = "sha256-feMj9NJrE6LxhCvyUwhabAqpxmF/vUDgIajlep9iS+w=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    "-DCROCTOOL_VERSION_STRING=${version}"
    "-DCROCTOOL_COMMIT_HASH=${src.rev}"
  ];

  postInstall = ''
    ln -s croctool $out/bin/maptool
    ln -s croctool $out/bin/cfextract
    ln -s croctool $out/bin/modtool
  '';

  meta = with lib; {
    description = "A small collection of utilities for Croc";
    homepage    = "https://github.com/vs49688/CrocUtils";
    platforms   = platforms.all;
    license     = licenses.gpl2;
    maintainers = with maintainers; [ zane ];
  };
}
