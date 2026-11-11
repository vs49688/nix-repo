{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchNpmDeps,
  python3,
}:

buildNpmPackage (finalAttrs: {
  pname = "pi-lsp-extension";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "samfoy";
    repo = "pi-lsp-extension";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rg6UfftvnSmX880Kf9vAg89FWeQOB0rOltN1cKoocwE=";
  };

  ##
  # The upstream lockfile cannot be prefetched as-is: it records the
  # @earendil-works workspace packages that pi-coding-agent pulls in at dev
  # time without integrity hashes, which aborts prefetch-npm-deps. Nothing this
  # package ships comes from devDependencies -- dist/ is checked in and Pi
  # supplies the peer packages -- so both the cache and the build source drop
  # them, leaving the upstream runtime versions untouched.
  ##
  postPatch = ''
    python3 ${./prune-dev-deps.py} package.json package-lock.json
  '';

  ##
  # fetchNpmDeps needs python3 for postPatch, which buildNpmPackage does not
  # forward to the cache derivation.
  ##
  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";

    inherit (finalAttrs) src postPatch;

    nativeBuildInputs = [ python3 ];

    hash = "sha256-01HKC9xINzxTO5VgLeKee3PKUHppucjZsUAq2nv3OJg=";
  };

  ##
  # The peer packages are installed from Pi's own tree, never from here: a
  # physical copy would duplicate its classes and registries.
  ##
  npmFlags = [ "--legacy-peer-deps" ];

  ##
  # dist/ is checked in upstream; esbuild and tsx only exist to rebuild it. The
  # `prepack` script would run that build during install, so the checked-in
  # output is copied below rather than packed.
  ##
  dontNpmBuild = true;

  ##
  # The default install hook builds an npm prefix ($out/lib/node_modules/...).
  # Pi loads a local package in place, so the output root itself has to be the
  # package directory: manifest, dist and the runtime dependency tree.
  ##
  dontNpmInstall = true;

  # Pi launches the daemon with process.execPath; patching its unused shebang
  # would retain a separate Node runtime in this library's closure.
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    if [ -e node_modules/@earendil-works ] || [ -e node_modules/typebox ]; then
      echo "error: host-provided Pi packages must not be installed in the package output" >&2
      exit 1
    fi

    mkdir -p $out
    cp -r package.json dist node_modules README.md CHANGELOG.md LICENSE $out/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Pi coding agent extension for LSP integration";
    homepage = "https://github.com/samfoy/pi-lsp-extension";
    license = licenses.mit;
    maintainers = with maintainers; [ zane ];
  };
})
