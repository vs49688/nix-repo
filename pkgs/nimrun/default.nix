{ stdenv, cmake, fetchFromGitHub, openssl, makeWrapper }:
stdenv.mkDerivation rec {
  name    = "nimrun";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner  = "UQ-RCC";
    repo   = "nimrod-embedded";
    rev    = "9f724e338ab02df270df9ffffabb83f3efa83ea8";
    sha256 = "1k947nmxzgkq2pwvq5x1ylmcfi69klxif7slzl2lzckc16jsk27w";
  };

  sourceRoot = "source/nimrun";

  nativeBuildInputs = [ cmake ];
  buildInputs       = [ openssl.dev makeWrapper ];
  cmakeFlags        = [ "-DCMAKE_EXE_LINKER_FLAGS=\"-static-libstdc++\"" ];

  installPhase = ''
    mkdir -p $out/bin
    cp nimrun $out/bin
  '';

  meta = with stdenv.lib; {
    description = "Nimrod/G Embedded Launch Utility";
    homepage    = "https://github.com/UQ-RCC/nimrod-embedded";
    platforms   = platforms.all;
    license     = licenses.asl20;
  };
}
