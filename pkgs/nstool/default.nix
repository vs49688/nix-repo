{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation(finalAttrs: {
  pname = "nstool";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "jakcron";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-NGuosc4Vwc4WA+b7mtn2WyJFPI4xfx/vJsd8S58js+U=";
    fetchSubmodules = true;
  };

  buildPhase = ''
    runHook preBuild

    make -j$NIX_BUILD_CORES $makeFlags deps
    make -j$NIX_BUILD_CORES PROJECT_BIN_PATH="${placeholder "out"}/bin" $makeFlags program

    runHook postBuild
  '';

  dontInstall = true;

  meta = with lib; {
    description = "General purpose read/extract tool for Nintendo Switch file formats";
    homepage = "https://github.com/jakcron/nstool";
    license = licenses.mit;
    maintainers = with maintainers; [ zane ];
    mainProgram = "nstool";
    platforms = platforms.all;
  };
})
