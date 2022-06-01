{ stdenv, pkgs, lib, buildGoModule, fetchFromGitHub, pkg-config, zlib, taglib, nodejs }:
let
  src = fetchFromGitHub {
    owner = "vs49688";
    repo = "navidrome";
    rev = "221763ff4b6ffcac553ea11cb8ff606e4572dd43";
    sha256 = "sha256-FgTxi4w46bdKNYIOQYMWlBhJYVRnnZElMkMuxcLn2L0=";
  };

  nodeDependencies = ((import ./node-composition.nix {
    inherit pkgs nodejs;
    inherit (stdenv.hostPlatform) system;
  }).nodeDependencies.override (old: {
    src = "${src}/ui";
  }));
in
buildGoModule {
  inherit src;

  pname = "navidrome-mbz";
  version = "unstable-2021-12-28";

  vendorSha256 = "sha256-xMAxGbq2VSXkF9R9hxB9EEk2CnqsRxg2Nmt7zyXohJI=";

  nativeBuildInputs = [
    pkg-config
    nodejs
  ];

  buildInputs = [
    zlib
    taglib
  ];

  passthru = {
    inherit nodeDependencies;
  };

  preBuild = ''
    pushd ui

    cp -R ${nodeDependencies}/lib/node_modules ./node_modules
    find node_modules -type d -print0 | xargs -0 chmod 0755
    npm install
    npm run check-formatting
    npm run lint
    npm run build

    popd
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