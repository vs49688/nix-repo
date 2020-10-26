{ stdenv, fetchurl, jre, which, makeWrapper }:
stdenv.mkDerivation rec {
  pname   = "nimrod-portal-backend";
  version = "1.3.0";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/nimrod-portal-backend/releases/download/${version}/nimrod-portal-backend-${version}.tar.gz";
    sha256 = "04ckdyr2gnnwsv046b2m6bl9p1r8m0rs74038yr2hgsyn4w0vy15";
  };

  buildInputs = [ makeWrapper ];

  installPhase = ''
    dest="$out/usr/share/nimrod-portal-backend"
    mkdir -p "$dest"
    cp -ra . "$dest"

    mkdir -p "$out/bin"
    makeWrapper "$dest/bin/nimrod-portal-backend" \
        "$out/bin/nimrod-portal-backend" \
        --prefix PATH : ${stdenv.lib.makeBinPath [ jre which ]} \
        --set JAVA_HOME ${jre.home}
  '';

  meta = with stdenv.lib; {
    description = "Nimrod Portal Backend Server";
    homepage    = "https://rcc.uq.edu.au/nimrod";
    license     = licenses.asl20;
    platforms   = platforms.all;
  };
}
