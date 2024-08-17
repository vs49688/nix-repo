{ lib
, stdenv
, fetchFromGitHub
, cmake
, cmakerc
, openssl
, nlohmann_json
, fmt_10
}:

stdenv.mkDerivation rec {
  pname = "umskt";
  version = "0.2.0-beta";

  src = fetchFromGitHub {
    owner = "UMSKT";
    repo = "UMSKT";
    rev = "v${version}";
    hash = "sha256-MmEg6b7QprD6AaCqzruBQH10Sor23jDD28KWYfeeCmQ=";
  };

  patches = [
	./no-cpm.patch
  ];

  cmakeFlags = [
    "-DUMSKT_USE_SHARED_OPENSSL=ON"
  ];

  nativeBuildInputs = [
    cmake
    cmakerc
  ];

  buildInputs = [
    openssl
    nlohmann_json
    fmt_10
  ];

  meta = with lib; {
    description = "Universal MS Key Toolkit";
    homepage = "https://github.com/UMSKT/UMSKT";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ ];
    mainProgram = "umskt";
    platforms = platforms.all;
  };
}
