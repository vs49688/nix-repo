{ stdenv
, fetchFromForgejo
, cmake
, zlib
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "jk_botti-fwgs";
  version = "unstable-2026-04-20-0";

  src = fetchFromForgejo {
    domain = "git.vs49688.net";
    owner = "zane";
    repo = "jk_botti";
    rev = "24b830dec6dc7c15086180701efba21df6b06632";
    hash = "sha256-trBctGwBxT6+xDxOb5jLEwuT1XpcB0sRVYqNtgN0Clc=";
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
