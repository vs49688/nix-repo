{ stdenv, cmake, fetchFromGitHub, openssl, makeWrapper }:
stdenv.mkDerivation rec {
  name    = "nimrun";
  # Not technically the version, just a placeholder
  version = "1.0.0";

  src = fetchFromGitHub {
    owner  = "UQ-RCC";
    repo   = "nimrod-embedded";
    rev    = "dcc7f3411d56870dadbe33dd0d9794ff690b7681";
    sha256 = "1y4glkdjlw8qmmv0kc42dlfayxbrqhqxd1bzijw18yms1ik1r4k2";
  };

  sourceRoot = "source/nimrun";

  nativeBuildInputs = [ cmake ];
  buildInputs       = [ openssl.dev makeWrapper ];
  cmakeFlags        = [
    "-DCMAKE_EXE_LINKER_FLAGS=\"-static-libstdc++\""
    "-DGIT_HASH=${src.rev}"
  ];

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
