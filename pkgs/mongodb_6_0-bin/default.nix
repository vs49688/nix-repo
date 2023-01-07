{ stdenv, lib, fetchurl, autoPatchelfHook, curl, lzma, openssl_1_1 }:
stdenv.mkDerivation {
  pname = "mongodb";
  version = "6.0.3";

  src = fetchurl {
    url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2004-6.0.3.tgz";
    sha256 = "sha256-CpWInJ6EhqDKMLAEZJBv/9X0QhcFgpQYP3J6kZLrD+k=";
  };

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
