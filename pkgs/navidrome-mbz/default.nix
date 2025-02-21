{ buildGoModule
, buildPackages
, fetchFromGitHub
, fetchNpmDeps
, lib
, nodejs
, npmHooks
, pkg-config
, stdenv
, ffmpeg-headless
, taglib
, zlib
, nixosTests
, nix-update-script
, ffmpegSupport ? true
}:

buildGoModule rec {
  pname = "navidrome";
  version = "0.54.5-mbz";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = "navidrome";
    rev = "v${version}";
    hash = "sha256-RnowuSpjaf1S+JqjJqvjifYm517maH5TaxHoUvVBIH8=";
  };

  vendorHash = "sha256-bI0iDhATvNylKnI81eeUpgsm8YqySPyinPgBbcO0y4I=";

  npmRoot = "ui";

  npmDeps = fetchNpmDeps {
    inherit src;
    sourceRoot = "${src.name}/ui";
    hash = "sha256-PaE1xcZX9wZRcKeqQCXbdhi4cIBWBL8ZQdww6AOB7sQ=";
  };

  nativeBuildInputs = [
    buildPackages.makeWrapper
    nodejs
    npmHooks.npmConfigHook
    pkg-config
  ];

  overrideModAttrs = oldAttrs: {
    nativeBuildInputs = lib.filter (drv: drv != npmHooks.npmConfigHook) oldAttrs.nativeBuildInputs;
    preBuild = null;
  };

  buildInputs = [
    taglib
    zlib
  ];

  ldflags = [
    "-X github.com/navidrome/navidrome/consts.gitSha=${src.rev}"
    "-X github.com/navidrome/navidrome/consts.gitTag=v${version}"
  ];

  tags = [
    "netgo"
  ];

  CGO_CFLAGS = lib.optionals stdenv.cc.isGNU [ "-Wno-return-local-addr" ];

  postPatch = ''
    patchShebangs ui/bin/update-workbox.sh
  '';

  preBuild = ''
    make buildjs
  '';

  postFixup = lib.optionalString ffmpegSupport ''
    wrapProgram $out/bin/navidrome \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg-headless ]}
  '';

  passthru = {
    tests.navidrome = nixosTests.navidrome;
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Navidrome with MusicBrainz patches";
    mainProgram = "navidrome";
    homepage = "https://github.com/vs49688/navidrome";
    license = lib.licenses.gpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    maintainers = with lib.maintainers; [ zane ];
    # Broken on Darwin: sandbox-exec: pattern serialization length exceeds maximum (NixOS/nix#4119)
    broken = stdenv.isDarwin;
  };
}
