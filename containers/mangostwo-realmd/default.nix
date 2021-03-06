{ dockerTools
, imagePrefix
, lib
, mangostwo-server
, mangostwo-database
, mariadb-client
, busybox
, runCommandLocal
}:
let
  uidstr = "1000";
  gidstr = "1000";
  user   = "mangos";
  group  = "mangos";

  entrypoint = runCommandLocal "entrypoint" {
    meta = lib.platforms.unix;
  } ''
    mkdir -p $out/bin
    cp ${./docker-entrypoint.sh} $out/bin/docker-entrypoint.sh
    chmod +x $out/bin/docker-entrypoint.sh
  '';

in dockerTools.buildLayeredImage {
  name = "${imagePrefix}/mangostwo-realmd";
  tag  = mangostwo-server.version;

  contents = [
    mangostwo-server
    mangostwo-database
    mariadb-client
    entrypoint
    busybox
  ];

  fakeRootCommands = ''
    mkdir ./{config,etc}
    chown ${uidstr}:${gidstr} ./config

    printf 'root:x:0:0::/root:/bin/nologin\n' > ./etc/passwd
    printf '${user}:x:${uidstr}:${gidstr}::/home/${user}:\n' >> ./etc/passwd

    printf 'root:x:0:\n' > ./etc/group
    printf '${user}:x:${uidstr}:\n' >> ./etc/group
  '';

  config = {
    Entrypoint  = [ "/bin/docker-entrypoint.sh" ];
    ExposedPort = { "3724" = {}; };
    User        = uidstr;
  };
}
