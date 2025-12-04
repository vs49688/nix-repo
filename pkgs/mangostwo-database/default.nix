{ stdenvNoCC
, lib
, fetchFromGitHub
, fetchFromGitea
, makeWrapper
, libmysqlclient
, which
, busybox
}:
stdenvNoCC.mkDerivation {
  pname   = "mangostwo-database";
  version = "unstable-2024-01-08.0";

  src = fetchFromGitHub {
    owner           = "mangostwo";
    repo            = "database";
    rev             = "269d7ade265b268f7bc2316e6b9d5a8a4186fc2a";
    fetchSubmodules = true;
    hash            = "sha256-7qvf3plYcZhD+kjnLDX7QV5icChzpK72Dk6NWpbe2Jk=";
  };

  dontConfigure = true;
  dontbuild     = true;

  patches = [
    # ./0001-InstallDatabases.sh-use-mariadb-socket.patch
    ./0002-InstallDatabases.sh-fix-importing-with-mariadb.patch
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mangos/database $out/bin
    cp -R . $out/share/mangos/database

    runHook postInstall
  '';

  nativeBuildInputs = [ makeWrapper ];

  preFixup = ''
    makeWrapper "$out/share/mangos/database/InstallDatabases.sh" \
        "$out/bin/InstallDatabases.sh" \
        --prefix PATH : ${lib.makeBinPath [ libmysqlclient which busybox ]} \
        --run "cd $out/share/mangos/database"

    # Remove "DEFINER=`root`@`localhost`". This needs to recurse into submodules,
    # so it can't be done as a patch.
    find $out/share/mangos/database -name '*.sql' -print0 | xargs -0 sed -i 's/DEFINER=`root`@`localhost` //g'
  '';

  meta = with lib; {
    description = "The Mangos TWO world database contains creatures, NPCs, Quests, Items/objects & gossip information to populate the in-game world with";
    homepage    = "https://www.getmangos.eu/bug-tracker/mangos-two/";
    platforms   = platforms.linux;
    license     = licenses.cc-by-nc-sa-30;
    maintainers = with maintainers; [ zane ];
  };
}
