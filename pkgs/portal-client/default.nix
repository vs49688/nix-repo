{ stdenv, lib, fetchurl, jre, busybox, makeWrapper }:
stdenv.mkDerivation rec {
  pname   = "portal-client";
  version = "1.0.7";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/portal-client/releases/download/${version}/portal-client-${version}.tar.gz";
    sha256 = "13q6h2swi8whylkmahvnabpvfxsgkiqsr9x9i5ap1ap8y5wpqbn2";
  };

  buildInputs = [ makeWrapper ];

  installPhase = ''
    dest="$out/usr/share/portal-client"
    mkdir -p "$dest"
    cp -ra . "$dest"

    mkdir -p "$out/bin"
    makeWrapper "$dest/bin/portal-client" \
        "$out/bin/portal-client" \
        --prefix PATH : ${lib.makeBinPath [ jre busybox ]} \
        --set JAVA_HOME ${jre.home}
  '';

  meta = with lib; {
    description = "RCC Portal Client";
    homepage    = "https://rcc.uq.edu.au/nimrod";
    license     = licenses.asl20;
    platforms   = platforms.linux;
  };
}
