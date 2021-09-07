{ stdenv, fetchurl }:
stdenv.mkDerivation rec {
  pname   = "ipp";
  version = "1.1.1";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/ipp/releases/download/${version}/ipp-${version}.tar.gz";
    sha256 = "1v7d5qrfs1fnxglrqjdnmzlcl6n254s82xc8hp9d43g8bzxlnccx";
  };

  dontConfigure = true;
  dontBuild     = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/${pname}
    mv * $out/share/${pname}
    find $out/share/${pname} -type d -print0 | xargs -0 chmod 0755
    find $out/share/${pname} -type f -print0 | xargs -0 chmod 0644

    runHook postInstall
  '';
}