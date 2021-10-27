{ dockerTools
, lib
, pkg ? null
, tini
, darkhttpd
, busybox
, name
, tag
, staticPath
, listenPort ? 8080
, noListing ? true
, noShell ? false
}:
dockerTools.buildLayeredImage {
  inherit name;
  inherit tag;

  contents = [ tini darkhttpd ]
    ++ lib.optionals (pkg != null) [ pkg ]
    ++ lib.optionals (!noShell) [ busybox ]
  ;

  config = {
    Cmd = [
      "/bin/tini" "--"
      "/bin/darkhttpd" staticPath "--port" "${toString listenPort}"
    ] ++ lib.optionals noListing ["--no-listing"];
  };
}
