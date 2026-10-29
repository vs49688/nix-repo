{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "kuna";
  version = "1.985";

  src = fetchFromGitHub {
    owner = "Noelo-Lab";
    repo = "kuna";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JBPoSQH56UzLERTwoiBMPO6GGgl+qT8R/4UxJdIp0Qw=";
  };

  ##
  # The Rust workspace lives one level down, and `cargoRoot` is what points
  # cargoSetupHook at decompiler/Cargo.lock and its vendored dependencies.
  ##
  cargoRoot = "decompiler";
  cargoHash = "sha256-YgszQlq5uhmKqbgqpvbX/ox2Jtm3GB8QND61DB/Tohs=";

  ##
  # A `kuna` binary is only self-contained with the compiled SLEIGH tree
  # inside it, and that is a two-pass build: slacomp turns specs/*.slaspec into
  # .sla next to the sources, then kuna-cli's build.rs `include_bytes!`s them
  # under the embed-specs feature. Without it the binary would look for the
  # tree on disk instead. docs/release.md has the same sequence.
  ##
  buildPhase = ''
    runHook preBuild

    pushd decompiler

    # Let stdenv strip, as cargoBuildHook does.
    export "CARGO_PROFILE_RELEASE_STRIP"=false

    # Release CI sets this; kuna-cli bakes it in via option_env! and prints it
    # for `kuna --version`. Without it the workspace's semver (0.1.0) is used.
    export KUNA_VERSION="${finalAttrs.version}"

    cargo build --release --offline -p kuna-slacomp
    ./target/release/slacomp -a ../specs
    cargo build --release --offline -p kuna-cli --features embed-specs

    popd

    runHook postBuild
  '';

  dontCargoInstall = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 decompiler/target/release/kuna $out/bin/kuna

    ##
    # The agent skill is embedded in the binary, so installing it here keeps it
    # a store path: agents link it instead of `kuna install-skill` writing a
    # copy into $HOME. Upstream would place it at <dir>/<skill name>/, where the
    # skill names itself kuna-decompiler.
    ##
    mkdir -p $out/share/kuna
    cp -r skills/kuna $out/share/kuna/skill

    runHook postInstall
  '';

  ##
  # The suite drives Ghidra fixtures through a sibling decomp_test_dbg, and
  # make test's canaries reach for a Ghidra install; neither is available in
  # the sandbox. The build itself is the check here.
  ##
  doCheck = false;

  meta = with lib; {
    description = "Agent-first decompiler, originally ported from Ghidra";
    homepage = "https://github.com/Noelo-Lab/kuna";
    license = licenses.asl20;
    mainProgram = "kuna";
    maintainers = with maintainers; [ zane ];
    platforms = platforms.linux;
  };
})
