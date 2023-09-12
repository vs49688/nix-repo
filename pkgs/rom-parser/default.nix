{ lib, stdenv, fetchFromGitHub }:
stdenv.mkDerivation {
  pname = "rom-parser";
  version = "unstable-2017-03-31";

  src = fetchFromGitHub {
    owner = "awilliam";
    repo = "rom-parser";
    rev = "94a615302f89b94e70446270197e0f5138d678f3";
    hash = "sha256-SSG959zEgFzQpGqMZsX3KXrGKUt7AaSqk2/pux8By+4=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mv rom-parser rom-fixer $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/awilliam/rom-parser";
    platforms = platforms.linux;
    maintainers = with maintainers; [ zane ];
  };
}
