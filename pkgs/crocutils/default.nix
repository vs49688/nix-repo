{ stdenv, lib, cmake, fetchFromGitHub }:
stdenv.mkDerivation rec {
  pname   = "CrocUtils";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner  = "vs49688";
    repo   = pname;
    rev    = version;
    sha256 = "01q8m08fjj77zkzxdd00c8wp8fczva1npncjyjs0jcnk40by0ypq";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake ];

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
