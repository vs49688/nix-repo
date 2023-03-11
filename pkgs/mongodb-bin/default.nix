{ stdenv, lib, fetchurl, autoPatchelfHook, curl, lzma, openssl_1_1
, src, version }:
stdenv.mkDerivation {
  inherit version src;

  pname = "mongodb";

  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    curl
    lzma
    openssl_1_1
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    mv bin $out
    rm -f $out/bin/mongoreplay

    runHook postInstall
  '';

  meta = with lib; {
    description = "A scalable, high-performance, open source NoSQL database";
    homepage = "http://www.mongodb.org";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfree;
    maintainers = with maintainers; [ zane ];
  };
}