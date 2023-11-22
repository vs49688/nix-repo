{ stdenv, pkgs, lib, buildGoModule, fetchFromGitHub, pkg-config, makeWrapper
, zlib, taglib, nodejs
, ffmpeg-headless, ffmpegSupport ? true }:
let
  pname = "navidrome-mbz";
  version = "0.50.1-mbz";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = "navidrome";
    rev = "v${version}";
    hash = "sha256-h5zHq1FdRrUTSWUos1f4aGZUo7iusaARgjVgAA0kNhY=";
  };

  nodeComposition = import ./node-composition.nix {
    inherit pkgs nodejs;
    inherit (stdenv.hostPlatform) system;
  };

  ui = nodeComposition.package.override {
    inherit version;

    pname = "${pname}-ui";

    src = "${src}/ui";

    dontNpmInstall = true;

    postInstall = ''
      npm run build
      cd $out
      mv lib/node_modules/navidrome-ui/build/* .
      rm -rf lib
    '';
  };
in
buildGoModule {
  inherit pname version src;

  vendorHash = "sha256-PKj2zJhGR1yETLZ4as35cuwil3vfyFKfkKF/32YdAt8=";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    zlib
    taglib
  ];

  ldflags = [
    "-X github.com/navidrome/navidrome/consts.gitSha=${lib.substring 0 7 src.rev}"
    "-X github.com/navidrome/navidrome/consts.gitTag=v${version}-SNAPSHOT"
  ];

  passthru = {
    inherit ui nodeComposition;
  };

  preBuild = ''
    rm -rf ui/build
    cp -R ${ui} ui/build
  '';

  postFixup = lib.optionalString ffmpegSupport ''
    wrapProgram $out/bin/navidrome \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg-headless ]}
  '';

  meta = with lib; {
    description = "Navidrome with MusicBrainz patches";
    homepage = "https://github.com/vs49688/navidrome";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
}
