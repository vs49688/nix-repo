{ dockerTools, pkgs, navidrome, cacert }: let
  # Because the nixpkgs one has a 500mb closure
  ffmpeg = pkgs.callPackage ./ffmpeg.nix { };
in dockerTools.buildLayeredImage {
  name = navidrome.pname;
  tag  = navidrome.version;

  contents = [
    (navidrome.override { inherit ffmpeg; })
    cacert
  ];

  config = {
    Cmd = [
      "/bin/navidrome"
    ];

    Env = [
      "ND_ADDRESS=0.0.0.0"
      "ND_PORT=4533"
      "ND_ENABLEEXTERNALSERVICES=false"
    ];

    ExportPorts = {
      "4533/tcp" = {};
    };
  };
}