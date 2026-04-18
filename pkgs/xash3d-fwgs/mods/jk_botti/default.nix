{ stdenv
, fetchFromGitHub
, cmake
, zlib
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "jk_botti-fwgs";
  version = "unstable-2026-03-22-0";

  src = fetchFromGitHub {
    owner = "Bots-United";
    repo = "jk_botti";
    rev = "6d23316cc33fc4e62a972d50327d7c09dd0245b9";
    hash = "sha256-OCSxGZJfDTD8nWMvVP9gaAxvde0TEbSaX8mArPRO50k=";
  };

  prePatch = ''
    rm -rf zlib
  '';

  patches = [
    ./0001-cmake-add.patch
    ./0002-util-use-actual-gamedir-for-file-lookups.patch
  ];

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
