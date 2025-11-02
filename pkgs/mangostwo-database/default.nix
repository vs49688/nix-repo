{ stdenvNoCC, lib, fetchFromGitHub, fetchFromGitea, makeWrapper, mariadb, which, busybox }: let
  translations = fetchFromGitea {
    domain = "git.vs49688.net";
    owner = "public-mirrors";
    repo = "MangosTwo_Localised";
    rev = "e239b13be18bb90a786911e2c3561c949720a148";
    hash = "sha256-M+NpqmeCeq/0B0LYEfpsVBhOrspArk3GSs1Xu5KOAaQ=";
  };

  realm = fetchFromGitHub {
    owner = "mangos";
    repo = "Realm_DB";
    rev = "3e0f816bec27063661993a85584b364d8513046b";
    hash = "sha256-siZChr/nzvi3ces3kwDS1Op1ceO4iLNUFX37j53mdSo=";
  };
in stdenvNoCC.mkDerivation {
  pname   = "mangostwo-database";
  version = "20211231";

  src = fetchFromGitHub {
    owner           = "mangostwo";
    repo            = "database";
    rev             = "bbaf1232605614eb8aabe6e967cc4191ef62886b";
    fetchSubmodules = false;
    hash            = "sha256-inbzrIZf922JgcaZ+S5j09oO6ajvUHuMcuJ0IOoelc8=";
  };

  dontConfigure = true;
  dontbuild     = true;

  prePatch = ''
    rmdir Realm
    ln -s ${realm} Realm

    rmdir Translations
    ln -s ${translations} Translations
  '';

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
        --prefix PATH : ${lib.makeBinPath [ mariadb.client which busybox ]} \
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
