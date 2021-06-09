{ stdenv, fetchurl }:
stdenv.mkDerivation rec {
  pname   = "nimrod-portal";
  version = "1.2.1";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/nimrod-portal/releases/download/1.2.1/nimrod-portal-1.2.1.tar.gz";
    sha256 = "0csyf3wnjhlia1l5vl7snln1bx6hs87jg7g63hyi0g6pijwz80ci";
  };

  dontConfigure = true;
  dontBuild     = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    mv * $out
    find $out -type d -print0 | xargs -0 chmod 0755
    find $out -type f -print0 | xargs -0 chmod 0644

    runHook postInstall
  '';
}