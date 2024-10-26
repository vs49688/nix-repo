{ stdenv
, lib
, fetchurl
, autoPatchelfHook
, curl
, xz
, openssl_1_1
, src
, version
}:
let
  # This is fine for a game.
  xssl = openssl_1_1.overrideAttrs (old: {
    meta = old.meta // { insecure = false; knownVulnerabilities = [ ]; };
  });
in
stdenv.mkDerivation {
  inherit version src;

  pname = "mongodb";

  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.libgcc or null
    curl
    xz
    xssl
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
