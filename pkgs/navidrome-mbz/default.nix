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
  version = "0.53.0-mbz";

  src = fetchFromGitHub {
    owner = "vs49688";
    repo = "navidrome";
    rev = "v${version}";
    hash = "sha256-4oIJBcLpmijQRyqOT4/Ns3Nsr5nRq4u3IRkhj5LOaNw=";
  };

  vendorHash = "sha256-+acLAn9cicXYRVn3tL+GzFeCxHtXHDMgKisu4BzvGQs=";

  npmRoot = "ui";

  npmDeps = fetchNpmDeps {
    inherit src;
    sourceRoot = "${src.name}/ui";
    hash = "sha256-SebqSsng/t6g2874Hejc9wubiyYLE0jb3oLFnGwTRMA=";
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

  CGO_CFLAGS = lib.optionals stdenv.cc.isGNU [ "-Wno-return-local-addr" ];

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
