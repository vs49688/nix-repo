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
    rev = "3c841b83f5445ed09dc16994fc4b0a3b3d01802b";
    hash = "sha256-Yj4SoPBob77cXi6GJUbK210ssLygDN9ilTkabxnAQu8=";
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
