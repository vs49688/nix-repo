{ stdenv
, lib
, fetchFromGitHub
, cmake
, pkg-config
, libmysqlclient
, bzip2
, zlib
, openssl
}:
stdenv.mkDerivation(finalAttrs: {
  pname   = "mangostwo";
  version = "22.02.138";

  src = fetchFromGitHub {
    owner           = finalAttrs.pname;
    repo            = "server";
    rev             = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash            = "sha256-VjjHh4D7HG/fDPpsgVQp3cdN9lHzwqcXlJKnTtV4Olw=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    libmysqlclient
    bzip2
    zlib
    openssl
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_MANGOSD" true)
    (lib.cmakeBool "BUILD_REALMD" true)
    (lib.cmakeBool "BUILD_TOOLS" true)
    (lib.cmakeBool "USE_STORMLIB" true)
    (lib.cmakeBool "SOAP" true)
    (lib.cmakeBool "SCRIPT_LIB_ELUNA" false) # FIXME: attempts to download lua
    (lib.cmakeBool "SCRIPT_LIB_SD3" true)
    # It complains about this. Will fix eventually...
    (lib.cmakeBool "PLAYERBOTS" false)
    (lib.cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
    (lib.cmakeBool "WITHOUT_GIT" true)
  ];

  postInstall = ''
    chmod +x $out/bin/tools/ExtractResources.sh $out/bin/tools/MoveMapGen.sh

    substituteInPlace $out/bin/tools/ExtractResources.sh \
      --replace-fail "./vmap-extractor"    "$out/bin/tools/vmap-extractor" \
      --replace-fail "./movemap-generator" "$out/bin/tools/mmap-extractor" \
      --replace-fail "./map-extractor"     "$out/bin/tools/map-extractor" \
      --replace-fail "./MoveMapGen.sh"     "$out/bin/tools/MoveMapGen.sh" \
      --replace-fail 'chmod +x "$bin"'     '# chmod +x "$bin"'

    substituteInPlace $out/bin/tools/MoveMapGen.sh \
      --replace-fail "./mmap-extractor"  "$out/bin/tools/mmap-extractor" \
      --replace-fail "offmesh.txt"       "$out/bin/tools/offmesh.txt" \
      --replace-fail "mmap_excluded.txt" "$out/bin/tools/mmap_excluded.txt"
  '';

  meta = with lib; {
    description = "Mangos TWO is a server for World of Warcraft: Wrath of The Lich king";
    homepage    = "https://www.getmangos.eu/bug-tracker/mangos-two/";
    platforms   = platforms.all;
    license     = licenses.gpl2Plus;
    maintainers = with maintainers; [ zane ];
  };
})
