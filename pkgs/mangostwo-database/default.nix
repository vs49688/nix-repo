{ stdenv, lib, fetchFromGitHub, makeWrapper, mysql-client, which, busybox }:
stdenv.mkDerivation {
  pname   = "mangostwo-database";
  version = "20210816";

  src = fetchFromGitHub {
    owner           = "mangostwo";
    repo            = "database";
    rev             = "550a412918f03863e8c47c2c4bb8c4b5f7501cf9";
    fetchSubmodules = true;
    sha256          = "1wk1315cwxf99bql9k2jf9hj8w4qmj99rxhff2jgrp0k2y2dgl21";
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
        --prefix PATH : ${lib.makeBinPath [ mysql-client which busybox ]} \
        --run "cd $out/share/mangos/database"

    # Remove "DEFINER=`root`@`localhost`". This needs to recurse into submodules,
    # so it can't be done as a patch.
    find $out/share/mangos/database -name '*.sql' -print0 | xargs -0 sed -i 's/DEFINER=`root`@`localhost` //g'
  '';

  meta = with lib; {
    description = "The Mangos TWO world database contains creatures, NPCs, Quests, Items/objects & gossip information to populate the in-game world with";
    homepage    = "https://www.getmangos.eu/bug-tracker/mangos-two/";
    platforms   = platforms.all;
    license     = licenses.cc-by-nc-sa-30;
    maintainers = with maintainers; [ zane ];
  };
}
