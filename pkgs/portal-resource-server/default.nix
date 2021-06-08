{ stdenv, lib, fetchurl, jre, busybox, makeWrapper }:
stdenv.mkDerivation rec {
  pname   = "portal-resource-server";
  version = "1.0.9";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/portal-resource-server/releases/download/${version}/portal-resource-server-${version}.tar.gz";
    sha256 = "1b83nf5x0qfyif420dlxyxqnchypiiv0q20w8i9df842v601my1a";
  };

  buildInputs = [ makeWrapper ];

  installPhase = ''
    dest="$out/usr/share/portal-resource-server"
    mkdir -p "$dest"
    cp -ra . "$dest"

    mkdir -p "$out/bin"
    makeWrapper "$dest/bin/portal-resource-server" \
        "$out/bin/portal-resource-server" \
        --prefix PATH : ${lib.makeBinPath [ jre busybox ]} \
        --set JAVA_HOME ${jre.home}
  '';

  meta = with lib; {
    description = "RCC Portal Resource Server";
    homepage    = "https://github.com/UQ-RCC/portal-resource-server";
    license     = licenses.asl20;
    platforms   = platforms.all;
  };
}