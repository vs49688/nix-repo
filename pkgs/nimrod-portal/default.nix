{ stdenv, lib, fetchurl }:
stdenv.mkDerivation rec {
  pname   = "nimrod-portal";
  version = "1.2.2";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/nimrod-portal/releases/download/${version}/nimrod-portal-${version}.tar.gz";
    sha256 = "0mf6kz5iwfs5sz08v5yhw5fhq25y1ra8r452lwqbxwaxk3jiy894";
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

  meta = with lib; {
    description = "Nimrod Portal Frontend";
    homepage    = "https://nimrod.rcc.uq.edu.au";
    license     = licenses.asl20;
    platforms   = platforms.all;
  };
}