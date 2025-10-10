{ stdenv, lib, cmake, perl, fetchFromGitea, fetchpatch }:
stdenv.mkDerivation rec {
  pname   = "crocutils";
  version = "1.5.0";

  src = fetchFromGitea {
    domain = "git.vs49688.net";
    owner  = "zane";
    repo   = "CrocUtils";
    # I fucked up, needs to be just above 1.5.0 to get a submodule fix.
    rev    = "77ccd11dc741375f1be1a2be8de7a104657b622c";
    hash   = "sha256-zRScaokXu4EzIzwcLCvHpqIMnAbb4mLkHOa3DKTc6NU=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    perl
  ];

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
