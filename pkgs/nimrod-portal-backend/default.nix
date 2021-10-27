{ stdenv, lib, fetchurl, jre, busybox, makeWrapper }:
stdenv.mkDerivation rec {
  pname   = "nimrod-portal-backend";
  version = "1.13.1";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/nimrodg/releases/download/${version}/nimrod-portal-backend-${version}.tar.gz";
    sha256 = "1k13w1s19n5f7dp2wc977l7zz1chk9gchr46n0wk1bmady35s199";
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
