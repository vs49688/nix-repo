{ stdenv, cmake, fetchFromGitHub, openssl, makeWrapper }:
stdenv.mkDerivation rec {
  pname    = "nimrun";
  # Not technically the version, just a placeholder
  version = "1.0.0";

  src = fetchFromGitHub {
    owner  = "UQ-RCC";
    repo   = "nimrod-embedded";
    rev    = "d8acd7776352cc8b770b347a824efed77a419579";
    sha256 = "1jz904k3fsv3l3z7n2isf89sxhy9lzd35pxdwcjk1wsvw5wnvdcd";
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
