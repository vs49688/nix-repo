{ stdenv, cmake, fetchFromGitHub, openssl, makeWrapper }:
stdenv.mkDerivation rec {
  name    = "nimrun";
  # Not technically the version, just a placeholder
  version = "0.0.1";

  src = fetchFromGitHub {
    owner  = "UQ-RCC";
    repo   = "nimrod-embedded";
    rev    = "6e1cb0387b5f3df3380e2e7b56f0857eea84e37a";
    sha256 = "15j458rkv5l54ad3i6nn0qyl5xjsl3f2magl0v3rl1y8g1kp7c0x";
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
