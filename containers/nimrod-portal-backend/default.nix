{ pkgs
, dockerTools
, tini
, nimrod-portal-backend
}:
let
  pkg = nimrod-portal-backend;
in
dockerTools.buildImage {
  name = "uq-rcc/${pkg.pname}";
  tag  = pkg.version;

  contents = [ tini pkg ];

  runAsRoot = ''
    #!{pkgs.runtimeShell}
    mkdir /tmp
  '';

  config = {
    Cmd = [ "${tini}/bin/tini" "--" "${pkg}/bin/nimrod-portal-backend" ];
  };
}
