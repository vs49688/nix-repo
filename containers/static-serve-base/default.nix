{ dockerTools
, lib
, pkg ? null
, tini
, darkhttpd
, name
, tag
, staticPath
, listenPort ? 8080
, noListing ? true
}:
dockerTools.buildLayeredImage {
  inherit name;
  inherit tag;

  contents = [ tini darkhttpd ] ++ lib.optionals (pkg != null) [ pkg ];

  config = {
    Cmd = [
      "/bin/tini" "--"
      "/bin/darkhttpd" staticPath "--port" "${toString listenPort}"
    ] ++ lib.optionals noListing ["--no-listing"];
  };
}
