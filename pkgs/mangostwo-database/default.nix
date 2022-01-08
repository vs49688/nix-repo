{ stdenv, lib, fetchFromGitHub, makeWrapper, mysql-client, which, busybox }:
stdenv.mkDerivation {
  pname   = "mangostwo-database";
  version = "20211231";

  src = fetchFromGitHub {
    owner           = "mangostwo";
    repo            = "database";
    rev             = "bbaf1232605614eb8aabe6e967cc4191ef62886b";
    fetchSubmodules = true;
    sha256          = "1432y1m0z05b3p631j900f8y0h85ix8irryzk9sqmy0wj6awgg0k";
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
