{ dockerTools
, pkg
, tini
, darkhttpd
, name    ? "uq-rcc/${pkg.pname}"
, tag     ? pkg.version
}:
dockerTools.buildLayeredImage {
  inherit name;
  inherit tag;

  contents = [ tini darkhttpd ];

  config = {
    Cmd = [
      "${tini}/bin/tini" "--"
      "${darkhttpd}/bin/darkhttpd" "${pkg}" "--port" "8080" "--no-listing"
    ];
  };
}