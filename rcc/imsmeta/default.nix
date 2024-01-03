{ stdenv, lib, cmake, fetchFromGitHub }:
stdenv.mkDerivation rec {
  pname    = "imsmeta";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner  = "UQ-RCC";
    repo   = pname;
    rev    = version;
    sha256 = "16rvnyp65zd4hm176alf3hylrqw4vammws6gir8ssya9kmcv6qa6";
  };

  nativeBuildInputs = [ cmake ];

  installPhase = ''
    mkdir -p $out/bin
    cp imsmeta $out/bin
  '';

  meta = with lib; {
    description = "Dragonfly Metadata to JSON converter";
    homepage    = "https://github.com/UQ-RCC/ims2tif";
    platforms   = platforms.all;
    license     = licenses.asl20;
  };
}
