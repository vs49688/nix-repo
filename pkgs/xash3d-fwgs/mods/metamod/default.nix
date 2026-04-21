{ stdenv
, fetchFromGitHub
, cmake
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "metamod-fwgs";
  version = "unstable-2026-04-21-0";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = "metamod-fwgs";
    rev = "9868c015e32d3f64c5835021547cdf61cc710c61";
    hash = "sha256-VNgLjXq8cSTslt0i5YdDHj65xXhPPntZft935/zdlXw=";
    fetchSubmodules = true;
    deepClone = true;

    postFetch = ''
      pushd $out
      git rev-list --count HEAD > GIT_COMMIT_COUNT
      git log HEAD -1 --format=%h > GIT_COMMIT_SHA
      git log HEAD -1 --format=%ad --date='format:%b %d %Y' > GIT_COMMIT_DATE
      git log HEAD -1 --format=%ad --date='format:%H:%M:%S' > GIT_COMMIT_TIME
      rm -rf .git
      popd
    '';
  };

  preConfigure = ''
    cmakeFlagsArray+=(-DAPP_COMMIT_COUNT="$(cat ${finalAttrs.src}/GIT_COMMIT_COUNT)")
    cmakeFlagsArray+=(-DAPP_COMMIT_SHA="$(cat ${finalAttrs.src}/GIT_COMMIT_SHA)")
    cmakeFlagsArray+=(-DAPP_COMMIT_DATE="$(cat ${finalAttrs.src}/GIT_COMMIT_DATE)")
    cmakeFlagsArray+=(-DAPP_COMMIT_TIME="$(cat ${finalAttrs.src}/GIT_COMMIT_TIME)")
  '';

  nativeBuildInputs = [
    cmake
  ];
})
