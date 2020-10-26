{ pkgs
, dockerTools
, tini
, portal-client
}:
let
  pkg = portal-client;
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
    Cmd = [ "${tini}/bin/tini" "--" "${pkg}/bin/portal-client" ];
  };
}
