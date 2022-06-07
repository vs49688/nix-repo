{ stdenv, pkgs, lib, buildGoModule, fetchFromGitHub, pkg-config, zlib, taglib, nodejs }:
let
  pname = "navidrome-mbz";
  version = "unstable-2022-06-06";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = "navidrome";
    rev = "31119e7b142f43f62b2c62f7bcb1e97e2c195706";
    sha256 = "sha256-mgpGH4X599xAgVDqUpcl/Eqzz7V87g2K2ddg0O7rs8U=";
  };

  nodeDependencies = ((import ./node-composition.nix {
    inherit pkgs nodejs;
    inherit (stdenv.hostPlatform) system;
  }).nodeDependencies.override (old: {
    src = "${src}/ui";
  }));

  ui = stdenv.mkDerivation {
    inherit version src;

    pname = "${pname}-ui";

    sourceRoot = "source/ui";

    nativeBuildInputs = [
      nodejs
    ];

    buildPhase = ''
      runHook preBuild

      cp -R ${nodeDependencies}/lib/node_modules ./node_modules
      find node_modules -type d -print0 | xargs -0 chmod 0755
      npm install
      npm run check-formatting
      npm run lint
      npm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mv build $out

      runHook postInstall
    '';
  };
in
buildGoModule {
  inherit pname version src;

  vendorSha256 = "sha256-xMAxGbq2VSXkF9R9hxB9EEk2CnqsRxg2Nmt7zyXohJI=";

  nativeBuildInputs = [
    pkg-config
    nodejs
  ];

  buildInputs = [
    zlib
    taglib
  ];

  ldflags = [
    "-s" "-w"
    "-X github.com/navidrome/navidrome/consts.gitSha=${lib.substring 0 7 src.rev}"
    "-X github.com/navidrome/navidrome/consts.gitTag=v0.47.5-mbz-SNAPSHOT"
  ];

  passthru = {
    inherit ui nodeDependencies;
  };

  preBuild = ''
    rm -rf ui/build
    cp -R ${ui} ui/build
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