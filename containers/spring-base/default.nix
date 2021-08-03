{ pkgs
, pkg
, name    ? "uqrcc/${pkg.pname}"
, tag     ? pkg.version
, command ? "${pkg}/bin/${pkg.pname}"
, args    ? []
, uid     ? 1000
, gid     ? 1000
, extra   ? []
}:
let
  etcDir = "${pkg}/usr/share/${pkg.pname}/etc/${pkg.pname}";
in
with pkgs; dockerTools.buildLayeredImage {
  inherit name;
  inherit tag;

  contents = [ tini busybox pkg ] ++ extra;

  fakeRootCommands = let
    uidstr = toString uid;
    gidstr = toString gid;
  in ''
    mkdir -p ./tmp ./etc

    printf 'root:x:0:0::/root:${busybox}/bin/ash\n' > ./etc/passwd
    printf '${pkg.pname}:x:${uidstr}:${gidstr}::/home/${pkg.pname}:\n' >> ./etc/passwd

    printf 'root:x:0:\n' > ./etc/group
    printf '${pkg.pname}:x:${uidstr}:\n' >> ./etc/group

    mkdir -p ./config ./home/${pkg.pname}
    cp ${etcDir}/application.yml ./config
    chmod 0600 ./config/application.yml
    chown -R "${uidstr}:${gidstr}" ./config ./home/${pkg.pname}
  '';

  config = {
    Cmd = [
      "${tini}/bin/tini" "--"
      command "--spring.config.location=/config/application.yml"
    ] ++ args;

    Volumes = {
      "/config" = {};
    };
  };
}