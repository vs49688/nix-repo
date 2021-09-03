{ stdenv, lib, fetchurl, jre, busybox, makeWrapper }:
stdenv.mkDerivation rec {
  pname   = "nimrod-portal-backend";
  version = "1.13.0";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/nimrod-portal-backend/releases/download/${version}/nimrod-portal-backend-${version}.tar.gz";
    sha256 = "1hw4k8qqm9mij0hvb7kyaam291sg7c1m3hv5a07sf7f7q348s22p";
  };

  buildInputs = [ makeWrapper ];

  installPhase = ''
    dest="$out/usr/share/nimrod-portal-backend"
    mkdir -p "$dest"
    cp -ra . "$dest"

    mkdir -p "$out/bin"
    makeWrapper "$dest/bin/nimrod-portal-backend" \
        "$out/bin/nimrod-portal-backend" \
        --prefix PATH : ${lib.makeBinPath [ jre busybox ]} \
        --set JAVA_HOME ${jre.home}
  '';

  meta = with lib; {
    description = "Nimrod Portal Backend Server";
    homepage    = "https://rcc.uq.edu.au/nimrod";
    license     = licenses.asl20;
    platforms   = platforms.all;
  };
}
