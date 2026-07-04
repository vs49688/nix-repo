{ stdenv
, lib
, callPackage
, fetchFromGitHub
, writeShellScriptBin
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
, bzip2
, freetype
, fontconfig
, dedicatedOnly ? false
}:

stdenv.mkDerivation(finalAttrs: let
  minigit = writeShellScriptBin "git" ''
    case "$*" in
        "describe --dirty --always")   cat ${finalAttrs.src}/GIT_VERSION     ;;
        "log -1 --format=%ci")         cat ${finalAttrs.src}/GIT_COMMIT_DATE ;;
        "rev-parse --abbrev-ref HEAD") cat ${finalAttrs.src}/GIT_BRANCH      ;;
        *) echo "git: '$*' is not a supported command" >&2; exit 1 ;;
    esac
  '';
in {
  pname = "xash3d-fwgs";
  version = "0-unstable-2026-07-01";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo  = finalAttrs.pname;
    rev = "9f2b8954e9a787dd74271186fe2930e14e2d2e8e";
    sha256 = "sha256-w8tgmMktEFQ7A0KztX+cNm7UZrl9H1+7wXhz7B0EKAw=";
    fetchSubmodules = true;
    deepClone = true;

    postFetch = ''
      pushd $out

      git describe --always > GIT_VERSION
      git log HEAD -1 --format=%ci > GIT_COMMIT_DATE
      # git rev-parse --abbrev-ref HEAD > GIT_BRANCH # This gives "fetchgit"
      echo master > GIT_BRANCH

      rm -rf 3rdparty/{bzip2,opus,libogg,vorbis,opusfile}
      rm -rf .git
      popd
    '';
  };

  nativeBuildInputs = [
    python3
    wafHook
    pkg-config
    minigit
  ];

  buildInputs = lib.optionals (!dedicatedOnly) [
    SDL2
    libX11
    libogg
    libvorbis
    libopus
    opusfile
    bzip2
    freetype
    fontconfig
  ];

  # Set the Epoch to 1980; otherwise the Python wheel/zip code
  # gets very angry
  preConfigure = ''
    find . -type f | while read file; do
      touch -d @315532800 $file;
    done

    mkdir -p .git # Force the WAF Git check to pass
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
