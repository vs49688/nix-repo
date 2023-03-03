{ stdenv, pkgs, lib, buildGoModule, fetchFromGitHub, pkg-config, makeWrapper
, zlib, taglib, nodejs
, ffmpeg-headless, ffmpegSupport ? true }:
let
  pname = "navidrome-mbz";
  version = "0.49.3-mbz";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = "navidrome";
    rev = "v${version}";
    sha256 = "sha256-BqY9sL6NU48pzGvgtl/VnGwfGwADsroKO3ajylkhM6Q=";
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

  vendorSha256 = "sha256-C8w/qCts8VqNDTQVXtykjmSbo5uDrvS9NOu3SHpAlDE=";

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

  preCheck = ''
    export GOFLAGS=''${GOFLAGS//-trimpath/}
  '';

  meta = with lib; {
    description = "Navidrome with MusicBrainz patches";
    homepage = "https://github.com/vs49688/navidrome";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
}
