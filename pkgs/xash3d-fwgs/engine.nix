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
  version = "unstable-2026-05-10-0";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo  = finalAttrs.pname;
    rev = "843f6297ed685cc5e41ce07793d01117fb94dc7f";
    sha256 = "sha256-7zrtCtFVB95mGIkuQm2ABuffnjbaTRFu7WEmvgGTCfs=";
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
