{ dockerTools
, lib
, pkg ? null
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

  contents = [ darkhttpd ] ++ lib.optionals (pkg != null) [ pkg ];

  config = {
    Cmd = [
      "/bin/darkhttpd" staticPath "--port" "${toString listenPort}"
    ] ++ lib.optionals noListing ["--no-listing"];
  };
}
