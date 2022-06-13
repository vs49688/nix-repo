{ dockerTools
, lib
, pkg ? null
, darkhttpd
, name
, tag
, staticPath
, listenPort ? 8080
, noListing ? true
, ...
}:
dockerTools.buildLayeredImage {
  inherit name;
  inherit tag;

  contents = [ darkhttpd ] ++ lib.optionals (pkg != null) [ pkg ];

  config = {
    Cmd = [
      "/bin/darkhttpd" staticPath "--port" "${toString listenPort}"
      "--no-server-id" "--chroot"
    ] ++ lib.optionals noListing ["--no-listing"];

    ExposedPorts = {
      "${toString listenPort}/tcp" = {};
    };
  };
}
