{ stdenv, lib, fetchFromGitHub, makeWrapper, openssl, zip }:
stdenv.mkDerivation rec {
  pname = "unifi-backup-decrypt";
  version = "unstable-2022-01-21";

  src = fetchFromGitHub {
    owner = "zhangyoufu";
    repo = "unifi-backup-decrypt";
    rev = "9e43825353669626ff738ad12a2befe4cc481d9f";
    sha256 = "1x9gihw8xqk3c9860srza4jcazwlcavngrfzzjl81lsi64gajkyi";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ openssl zip ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    cp $src/encrypt.sh $out/bin/unifi-backup-encrypt
    cp $src/decrypt.sh $out/bin/unifi-backup-decrypt

    wrapProgram $out/bin/unifi-backup-encrypt \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    wrapProgram $out/bin/unifi-backup-decrypt \
      --prefix PATH : ${lib.makeBinPath buildInputs}

    runHook postInstall
  '';

  meta = with lib; {
    homepage    = "https://github.com/zhangyoufu/unifi-backup-decrypt";
    platforms   = platforms.all;
    license     = licenses.unlicense;
    maintainers = with maintainers; [ zane ];
  };
}
