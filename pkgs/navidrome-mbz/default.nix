{ stdenv, pkgs, lib, buildGoModule, fetchFromGitHub, pkg-config, makeWrapper
, zlib, taglib, nodejs
, ffmpeg, ffmpegSupport ? true }:
let
  pname = "navidrome-mbz";
  version = "unstable-2022-10-07";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = "navidrome";
    rev = "b422d1359bfa43d27ca3e436b4f061239d1c5c60";
    sha256 = "sha256-klwnqF1DKR/EHtNbNKo/CWdeUUu2ToEx9md0pSBEiL8=";
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

  vendorSha256 = "sha256-LPoM5RFHfTTWZtlxc59hly12zzrY8wjXGZ6xW2teOFM=";

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
    "-X github.com/navidrome/navidrome/consts.gitTag=v0.47.5-mbz-SNAPSHOT"
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
      --prefix PATH : ${lib.makeBinPath [ ffmpeg ]}
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