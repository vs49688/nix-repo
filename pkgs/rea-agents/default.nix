{
  lib,
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage (finalAttrs: {
  pname = "rea-agents";
  version = "6.8.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${finalAttrs.version}.tgz";
    hash = "sha256-jVQux2qcs1BYS2CmycCIcG/4EtW7WwlMIMlbbcJWmLs=";
  };

  ##
  # The published tarball ships no lockfile, and its package.json still carries
  # upstream devDependencies and lifecycle scripts. Both vendored files are
  # generated from that package.json with devDependencies and scripts removed,
  # so npm ci resolves the runtime closure only.
  ##
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-RiK1mCNdw7+TBqwW036kpDCmSncxOcqQp42qC+XA/fk=";

  ##
  # frida's install script downloads a 112 MiB prebuilt binding from GitHub.
  # Nothing else needs a script, and frida is optional (dynamic JavaScript and
  # Electron instrumentation only), so refusing scripts costs nothing for
  # native work.
  ##
  npmFlags = [ "--ignore-scripts" ];

  # dist/ is prebuilt in the published tarball.
  dontNpmBuild = true;

  meta = with lib; {
    description = "MCP server and CLI for reverse engineering binaries, applications and runtime behaviour";
    homepage = "https://rea.tools";
    license = licenses.mit;
    maintainers = with maintainers; [ zane ];
    mainProgram = "rea";
    platforms = platforms.linux;
  };
})
