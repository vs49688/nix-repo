{ stdenv, lib, fetchFromGitHub }:
stdenv.mkDerivation rec {
  pname   = "darkhttpd";
  version = "1.13";

  src = fetchFromGitHub {
    owner  = "emikulic";
    repo   = pname;
    rev    = "v${version}";
    sha256 = "0w11xq160q9yyffv4mw9ncp1n0dl50d9plmwxb0yijaaxls9i4sk";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mv darkhttpd $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    description = "When you need a web server in a hurry";
    homepage    = "https://unix4lyfe.org/darkhttpd/";
    license     = licenses.isc;
    platforms   = platforms.linux;
  };
}
