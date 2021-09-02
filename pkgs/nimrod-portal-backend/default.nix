{ stdenv, lib, fetchurl, jre, busybox, makeWrapper }:
stdenv.mkDerivation rec {
  pname   = "nimrod-portal-backend";
  version = "1.4.2";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/nimrod-portal-backend/releases/download/${version}/nimrod-portal-backend-${version}.tar.gz";
    sha256 = "0fzzbsz3nclpcylawfpmqbfbbfhdv0r0fz2gkw09q4n9i87kk96c";
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
