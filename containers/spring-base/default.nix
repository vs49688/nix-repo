{ pkgs
, pkg
, name    ? "uq-rcc/${pkg.pname}"
, tag     ? pkg.version
, command ? "${pkg}/bin/${pkg.pname}"
, uid     ? 1000
, gid     ? 1000
}:
let
  etcDir = "${pkg}/usr/share/${pkg.pname}/etc/${pkg.pname}";
in
with pkgs; dockerTools.buildImage {
  inherit name;
  inherit tag;

  contents = [ tini busybox pkg ];

  runAsRoot = let
    uidstr = toString uid;
    gidstr = toString gid;
  in ''
    #!{pkgs.runtimeShell}
    ${dockerTools.shadowSetup}
    mkdir /tmp
    groupadd -r -g "${uidstr}" "${pkg.pname}"
    useradd  -r -g "${gidstr}" -u "${uidstr}" "${pkg.pname}"
    mkdir /config
    cp ${etcDir}/application.yml /config
    chmod 0600 /config/application.yml
    chown -R "${uidstr}:${gidstr}" /config
  '';

  config = {
    Cmd = [
      "${tini}/bin/tini" "--"
      command "--spring.config.location=/config/application.yml"
    ];

    Volumes = {
      "/config" = {};
    };
  };
}