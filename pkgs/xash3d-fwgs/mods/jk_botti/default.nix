{ stdenv
, fetchFromForgejo
, cmake
, zlib
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "jk_botti-fwgs";
  version = "unstable-2026-04-21-0";

  src = fetchFromForgejo {
    domain = "git.vs49688.net";
    owner = "zane";
    repo = "jk_botti";
    rev = "1a364d3142a383fce278d6f8ead9fc2da6b2beda";
    hash = "sha256-VRylyJKJzt/Y7DQ3JfEDBZfEdnBXrtuoAYUTJrNQJb8=";
  };

  prePatch = ''
    rm -rf zlib
  '';

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    zlib
  ];

  installPhase = ''
    runHook preInstall

    mkdir $out
    install -m755 libjk_botti_mm.so $out/libjk_botti_mm.so

    runHook postInstall
  '';
})
