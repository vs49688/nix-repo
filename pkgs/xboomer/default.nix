{ lib
, stdenvNoCC
, fetchFromGitHub
}:

stdenvNoCC.mkDerivation {
  pname = "xboomer";
  version = "unstable-2019-11-23";

  src = fetchFromGitHub {
    owner = "efskap";
    repo = "XBoomer";
    rev = "1e3f6c5f817ff2bf093119865984da6296d4e0f9";
    hash = "sha256-1DNbxNhUDfWRdqhY76y2weXn4BNmHureV0vKiwkJiBQ=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    mv aurorae $out/share

    runHook postInstall
  '';

  meta = with lib; {
    description = "Windows XP window decorations for KDE Plasma";
    homepage = "https://github.com/efskap/XBoomer";
    license = with licenses; [ gpl3Plus ];
    platforms = lib.platforms.unix;
    maintainers = with maintainers; [ zane ];
  };
}
