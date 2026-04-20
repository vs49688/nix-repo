{ stdenv
, lib
, callPackage
, fetchFromGitHub
, python3
, wafHook
, pkg-config
, cmake
, SDL2
, libX11
, libogg
, libvorbis
, libopus
, opusfile
, freetype
, fontconfig
, dedicatedOnly ? false
}:

stdenv.mkDerivation(finalAttrs: {
  pname = "xash3d-fwgs";
  version = "unstable-2026-04-19-0";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo  = finalAttrs.pname;
    rev = "306a5812a9894d328b91697f0f77232416a2216d";
    sha256 = "sha256-GHm/rp7KpXnrblLiD/VdKmOx2PR+DSnK4A4JkqZdFQE=";

    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    python3
    wafHook
    pkg-config
  ];

  buildInputs = lib.optionals (!dedicatedOnly) [
    SDL2
    libX11
    libogg
    libvorbis
    libopus
    opusfile
    freetype
    fontconfig
  ];

  # Set the Epoch to 1980; otherwise the Python wheel/zip code
  # gets very angry
  preConfigure = ''
    find . -type f | while read file; do
      touch -d @315532800 $file;
    done
  '';

  wafConfigureFlags = [
    "--build-type=humanrights"
    "--64bits"
    "--enable-packaging"
    "--enable-poly-opt"
    "--enable-openmp"
    "--enable-packaging"
    # "--enable-lto" # causes filesystem linker errors
  ] ++ (lib.optionals (dedicatedOnly) [
    "--dedicated"
  ]) ++ (lib.optionals (!dedicatedOnly) [
    # "--use-sdl3" # SDL3 support is shoddy
    "--enable-all-renderers"
    "--enable-dedicated"
    "--enable-utils"
    "--enable-xar"
  ]);

  dontUseWafInstall = false;

  wafInstallFlags = [
    "--destdir=/"
  ];

  passthru.dedicatedOnly = dedicatedOnly;
})
