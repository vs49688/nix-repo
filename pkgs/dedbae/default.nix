{ lib
, stdenv
, fetchFromGitLab
}:

stdenv.mkDerivation rec {
  pname = "dedbae";
  version = "unstable-2019-04-11";

  src = fetchFromGitLab {
    owner = "roothorick";
    repo = "dedbae";
    rev = "87b08da7c1e73c481cae635136240098013e832e";
    hash = "sha256-zGNMjxatW4SnSCqYxNuiEZ6qlHAgoGGhjgHth5BB5Ic=";
    fetchSubmodules = true;
  };

  makeFlags = [ "RELEASE=1" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out $lib
    cp -R bin include $out/
    cp -R lib $lib/

    runHook postInstall
  '';

  outputs = [ "out" "lib" "dev" ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Library and tools for manipulating Nintendo Switch file formats";
    homepage = "https://gitlab.com/roothorick/dedbae";
    license = licenses.isc;
    maintainers = with maintainers; [ zane ];
    mainProgram = "dedbae";
    platforms = platforms.all;
  };
}
