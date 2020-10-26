{ stdenv, fetchurl, jre, busybox, makeWrapper }:
stdenv.mkDerivation rec {
  pname   = "portal-client";
  version = "1.0.5";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/portal-client/releases/download/${version}/portal-client-${version}.tar.gz";
    sha256 = "1hdhk5nrqi60kqwl7ddfydszq00mlfjwn5yz8rbwx26q3qrr78dd";
  };

  buildInputs = [ makeWrapper ];

  installPhase = ''
    dest="$out/usr/share/portal-client"
    mkdir -p "$dest"
    cp -ra . "$dest"

    mkdir -p "$out/bin"
    makeWrapper "$dest/bin/portal-client" \
        "$out/bin/portal-client" \
        --prefix PATH : ${stdenv.lib.makeBinPath [ jre busybox ]} \
        --set JAVA_HOME ${jre.home}
  '';

  meta = with stdenv.lib; {
    description = "RCC Portal Client";
    homepage    = "https://rcc.uq.edu.au/nimrod";
    license     = licenses.asl20;
    platforms   = platforms.all;
  };
}
