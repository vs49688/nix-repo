{ stdenv, lib, cmake, fetchFromGitHub }:
stdenv.mkDerivation rec {
  name    = "extract-glb";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner  = "vs49688";
    repo   = name;
    rev    = version;
    sha256 = "10slj158fh43sq1sqaqbn55js6h3n3dr0ysxz27jk2z1v0rlx73h";
  };

  nativeBuildInputs = [ cmake ];

  installPhase = ''
    mkdir -p $out/bin
    cp extract-glb $out/bin
  '';

  meta = with lib; {
    description = "DemonStar GLB extractor";
    homepage    = "https://github.com/vs49688/extract-glb";
    platforms   = platforms.all;
    license     = licenses.asl20;
    maintainers = with maintainers; [ zane ];
  };
}
