{ stdenv
, fetchFromForgejo
, cmake
, zlib
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "jk_botti-fwgs";
  version = "unstable-2026-04-22-0";

  src = fetchFromForgejo {
    domain = "git.vs49688.net";
    owner = "zane";
    repo = "jk_botti";
    rev = "215b2c48ba2b21aac27d18156622fade1a584c36";
    hash = "sha256-kPPdNCBZ1I4pvyEUjN8RDCIBLiZ4bK2cp/5nFQ1A3Gw=";
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
