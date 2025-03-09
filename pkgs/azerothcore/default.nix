{ stdenv
, lib
, fetchFromGitHub
, cmake
, mysql84
, openssl
, zlib
, boost
, readline
, bzip2
}:

stdenv.mkDerivation(finalAttrs: {
  pname = "azerothcore";
  version = "unstable-2025-03-09";

  src = fetchFromGitHub {
    owner = "azerothcore";
    repo = "azerothcore-wotlk";
    rev = "f7778ccaf536912bd16682dd75295d52103187f7";
    hash = "sha256-L8c4ub+Irc0Sv43tjwYi1Mk12WH3P0upCbkdueNJies=";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    mysql84
    openssl
    boost
    readline
    bzip2
    zlib
  ];

  cmakeFlags = [
    "-DAPPS_BUILD=all"
    "-DTOOLS_BUILD=all"
    (lib.cmakeBool "WITHOUT_GIT" true)
    (lib.cmakeBool "WITH_DYNAMIC_LINKING" false) # Try it, I dare you
    (lib.cmakeBool "WITH_STRICT_DATABASE_TYPE_CHECKS" true)
  ];

  meta = with lib; {
    description = "Complete Open Source and Modular solution for MMO";
    homepage    = "https://www.azerothcore.org";
    platforms   = platforms.all;
    license     = [ licenses.gpl2Plus licenses.agpl3Plus ];
    maintainers = with maintainers; [ zane ];
  };
})
