{ pkgs
, dockerTools
, tini
, nimrod-portal-backend
}:
let
  pkg    = nimrod-portal-backend;
  etcDir = "${pkg}/usr/share/${pkg.pname}/etc/${pkg.pname}";
in
dockerTools.buildImage {
  name = "uq-rcc/${pkg.pname}";
  tag  = pkg.version;

  runAsRoot = ''
    #!{pkgs.runtimeShell}
    ${dockerTools.shadowSetup}
    mkdir /tmp
    groupadd -r ${pkg.pname}
    useradd -r ${pkg.pname}
    mkdir /config
    cp ${etcDir}/application.yml /config
    chmod 0600 /config/application.yml
    chown -R ${pkg.pname}:${pkg.pname} /config
  '';

  config = {
    Cmd = [
      "${tini}/bin/tini" "--"
      "${pkg}/bin/${pkg.pname}" "--spring.config.location=/config/application.yml"
    ];
    Volumes = {
      "/config" = {};
    };
  };
}
