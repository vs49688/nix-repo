{ stdenv
, fetchFromGitHub
, callPackage
, cmake
, qtbase
, wrapQtAppsHook
, glm
, spdlog
, openal-soft
}:
let
  libnyquist = callPackage ./libnyquist.nix { };
in
stdenv.mkDerivation(finalAttrs: {
  pname = "halflife-asset-manager";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "SamVanheer";
    repo = "HalfLifeAssetManager";
    tag = "HLAM-V${finalAttrs.version}";
    hash = "sha256-WkPRdWK+FNbe7qe91sdyq7FKckSUQxuk0WNdAMz24zU=";
  };

  patches = [
    ./patch.diff
  ];

  nativeBuildInputs = [
    cmake
    wrapQtAppsHook
  ];

  qtWrapperArgs = [
    "--set QT_QPA_PLATFORM xcb"
  ];

  buildInputs = [
    qtbase
    glm
    spdlog
    openal-soft
    libnyquist
  ];

  cmakeFlags = [
    "-DHLAM_GIT_BRANCH=master"
    "-DHLAM_GIT_TAG=${finalAttrs.src.tag}"
    "-DHLAM_GIT_COMMIT_HASH=4df74a58a50438b8f4b974e04ab9f24fdfcbb811"
  ];

  passthru.libnyquist = libnyquist;
})
