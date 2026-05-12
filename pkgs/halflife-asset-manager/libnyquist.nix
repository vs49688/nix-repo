{ stdenv
, fetchFromGitHub
, cmake
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "libnyquist";
  version = "unstable-2026-03-28-0";

  src = fetchFromGitHub {
    owner = "ddiakopoulos";
    repo = "libnyquist";
    rev = "2e47815ed53b3c042959d088b760ee525699aa66";
    hash = "sha256-chsyHIGl5IFapM2Oo84QPOxdbzx5xSRTEs7AzUdxFZ0=";
  };

  nativeBuildInputs = [
    cmake
  ];

  cmakeFlags = [
    "-DLIBNYQUIST_BUILD_EXAMPLE=OFF"
  ];

  postInstall = ''
    cp -rp ${finalAttrs.src}/include $out
  '';
})
