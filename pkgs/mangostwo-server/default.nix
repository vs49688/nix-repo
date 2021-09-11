{ stdenv, lib, fetchFromGitHub
, cmake, pkg-config
, libmysqlclient, bzip2, zlib, openssl
}:
stdenv.mkDerivation rec {
  pname   = "mangostwo";
  version = "22.01.81";

  src = fetchFromGitHub {
    owner           = pname;
    repo            = "server";
    rev             = "v${version}";
    fetchSubmodules = true;
    sha256          = "1ka5if8bjkvqclln4n2pq9w7yxgfadydlgz1z93dv5jipdbwpdlf";
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