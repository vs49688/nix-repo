{ lib
, stdenv
, fetchFromGitHub
, python
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "gogextract";
  version = "unstable-2016-10-09";

  src = fetchFromGitHub {
    owner = "Yepoleb";
    repo = "gogextract";
    rev = "6601b32feacecd18bc12f0a4c23a063c3545a095";
    hash = "sha256-BTtm3Tn2hFS512w+IcJQfGKSgi2dpYLg1VxNXRODBEI=";
  };

  dontBuild = true;

  buildInputs = [
    python
  ];

  installPhase = ''
    install -Dm755 gogextract.py $out/bin/gogextract
  '';

  meta = {
    description = "Script for unpacking GOG Linux installers";
    homepage = "https://github.com/Yepoleb/gogextract";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "gogextract";
    platforms = lib.platforms.all;
  };
})
