{ stdenv
, fetchFromGitHub
, cmake
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "metamod-fwgs";
  version = "unstable-2026-04-16-0";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "metamod-fwgs";
    rev = "eedede40e806e7f3d1604de61ed43404928ea639";
    hash = "sha256-gFUzYPeh33cMJRl0StVjb8kqD6oL2a6nbRVEIUloyjk=";
    fetchSubmodules = true;
    deepClone = true;

    postFetch = ''
      pushd $out
      git rev-list --count HEAD > GIT_COMMIT_COUNT
      git log HEAD -1 --format=%h > GIT_COMMIT_SHA
      git log HEAD -1 --format=%ad --date='format:%b %d %Y' > GIT_COMMIT_DATE
      git log HEAD -1 --format=%ad --date='format:%H:%M:%S' > GIT_COMMIT_TIME
      rm -rf .git
    '';
  };

  patches = [
    ./0001-metamod-allow-configuring-mm_-from-environment.patch
  ];

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
