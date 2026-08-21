{ lib, stdenv, fetchurl }:
stdenv.mkDerivation(finalAttrs: {
  pname = "gnupg";
  version = "1.4.23";

  src = fetchurl {
    url = "https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-1.4.23.tar.bz2";
    hash = "sha256-yUYvF+ZRtlB4SMCMQwx5EofNdUkfi1qLUMbtRrEmeLo=";
  };

  env.LDFLAGS = "-z muldefs";

  meta = with lib; {
    description = "GnuPG";
    homepage = "https://www.gnupg.org";
    platforms = platforms.all;
    license     = licenses.gpl3;
    maintainers = with maintainers; [ zane ];
  };
})