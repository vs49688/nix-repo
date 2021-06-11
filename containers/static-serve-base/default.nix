{ dockerTools
, pkg
, tini
, darkhttpd
, name       ? "uq-rcc/${pkg.pname}"
, tag        ? pkg.version
, staticPath ? "/share/${pkg.pname}"
, listenPort ? 8080
}:
dockerTools.buildLayeredImage {
  inherit name;
  inherit tag;

  contents = [ tini darkhttpd pkg ];

  config = {
    Cmd = [
      "/bin/tini" "--"
      "/bin/darkhttpd" staticPath "--port" "${toString listenPort}" "--no-listing"
    ];
  };
}
