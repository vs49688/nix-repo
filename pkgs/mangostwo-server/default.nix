{ stdenv, lib, fetchFromGitHub
, cmake, pkg-config
, libmysqlclient, bzip2, zlib, openssl
}:
stdenv.mkDerivation rec {
  pname   = "mangostwo";
  version = "22.01.94";

  src = fetchFromGitHub {
    owner           = pname;
    repo            = "server";
    rev             = "v${version}";
    fetchSubmodules = true;
    sha256          = "0v44wa2ydls2hnzg65l7ikqccpmf6gjdvgk99hka8cjpc5fdd77x";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs       = [ libmysqlclient bzip2 zlib openssl ];

  cmakeFlags = [
    "-DBUILD_BANGOSD=ON"
    "-DBUILD_REALMD=ON"
    "-DBUILD_TOOLS=ON"
    "-DUSE_STORMLIB=ON"
    "-DSOAP=ON"
    "-DSCRIPT_LIB_ELUNA=ON"
    "-DSCRIPT_LIB_SD3=ON"
    # It complains about this. Will fix eventually...
    #"-DPLAYERBOTS=ON"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Mangos TWO is a server for World of Warcraft: Wrath of The Lich king";
    homepage    = "https://www.getmangos.eu/bug-tracker/mangos-two/";
    platforms   = platforms.all;
    license     = licenses.gpl2Plus;
    maintainers = with maintainers; [ zane ];
  };
}