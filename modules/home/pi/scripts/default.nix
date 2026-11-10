{ stdenvNoCC, python3 }:
stdenvNoCC.mkDerivation(finalAttrs: {
  name = "pi-scripts";

  dontUnpack = true;
  dontBuild = true;

  buildInputs = [
    python3
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${./mine-sessions.py} $out/bin/mine-sessions

    runHook postInstall
  '';
})