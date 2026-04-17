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
}:

stdenv.mkDerivation(finalAttrs: {
  pname = "xash3d-fwgs";
  version = "unstable-2026-04-13-0";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo  = finalAttrs.pname;
    rev = "84b7b5803bed19651d5fa8873225126ffd1ba9d1";
    sha256 = "sha256-ojLLKJcS1og2kvrLAnpzg7S4RxX4eO/l9PZKn2R+WfQ=";

    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    python3
    wafHook
    pkg-config
  ];

  buildInputs = [
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
    # "--use-sdl3" # SDL3 support is shoddy
    "--build-type=humanrights"
    "--64bits"
    "--enable-all-renderers"
    "--enable-packaging"
    # "--enable-lto" # causes filesystem linker errors
    "--enable-poly-opt"
    "--enable-openmp"
    "--enable-packaging"
    "--enable-dedicated"
    "--enable-utils"
    "--enable-xar"
  ];

  dontUseWafInstall = false;

  wafInstallFlags = [
    "--destdir=/"
  ];
})
