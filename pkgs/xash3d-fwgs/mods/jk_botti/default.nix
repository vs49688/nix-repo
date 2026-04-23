{ stdenv
, fetchFromForgejo
, cmake
, zlib
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "jk_botti-fwgs";
  version = "unstable-2026-04-23-0";

  src = fetchFromForgejo {
    domain = "git.vs49688.net";
    owner = "zane";
    repo = "jk_botti";
    rev = "97cd2f6f408f73c1f316e445c61fcd4ff03b37e0";
    hash = "sha256-axnTm5aFtGAyybaeBdojGzvMyRV2pfD7cGXhYS6evVA=";
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
