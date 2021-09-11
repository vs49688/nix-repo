{ stdenv, lib, cmake, fetchFromGitHub }:
stdenv.mkDerivation rec {
  name    = "extract-drs";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner  = "vs49688";
    repo   = name;
    rev    = version;
    sha256 = "1833946x9aj2n0a0b3sn7zlmcm36vdkjn66qhdk73v754754b6qs";
  };

  nativeBuildInputs = [ cmake ];

  installPhase = ''
    mkdir -p $out/bin
    cp extract-drs $out/bin
  '';

  meta = with lib; {
    description = "AoE1 DRS extractor";
    homepage    = "https://github.com/vs49688/extract-drs";
    platforms   = platforms.all;
    license     = licenses.asl20;
    maintainers = with maintainers; [ zane ];
  };
}
