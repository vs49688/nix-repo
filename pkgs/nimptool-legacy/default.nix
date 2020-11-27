{ stdenv, cmake, fetchgit, makeWrapper }:
stdenv.mkDerivation rec {
  pname    = "nimptool-legacy";
  version = "0.0.1";

  ##
  # fetchFromGitHub didn't want to work, probably
  # because the repo is archived.
  ##
  src = fetchgit {
    url    = "https://github.com/UQ-RCC/nimptool";
    rev    = "a3a3ba722954b0158fd3483d7a0a8634d77531aa";
    sha256 = "0qv09xv2ybrgbgb27byqv497l4lv1x944a6rqwmhxms86v958lvi";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs       = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp nimptool $out/bin
  '';

  meta = with stdenv.lib; {
    description = "Nimrod Portal Tool (Legacy)";
    homepage    = "https://github.com/UQ-RCC/nimptool";
    platforms   = platforms.all;
    license     = licenses.asl20;
  };
}
