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
    hash            = "sha256-/ZzWXGFXMqQmTGm+3eQzrl7G8IyHFvO+hULT5oXihGw=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs       = [ libmysqlclient bzip2 zlib openssl ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_MANGOSD" true)
    (lib.cmakeBool "BUILD_REALMD" true)
    (lib.cmakeBool "BUILD_TOOLS" true)
    (lib.cmakeBool "USE_STORMLIB" true)
    (lib.cmakeBool "SOAP" true)
    (lib.cmakeBool "SCRIPT_LIB_ELUNA" true)
    (lib.cmakeBool "SCRIPT_LIB_SD3" true)
    # It complains about this. Will fix eventually...
    #(lib.cmakeBool "PLAYERBOTS" true)
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    (lib.cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
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