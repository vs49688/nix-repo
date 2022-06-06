{ stdenv, lib, fetchFromGitHub, makeWrapper, powershell }:
stdenv.mkDerivation {
  pname = "hg659-voip-password";
  version = "unstable-2017-06-21";

  src = fetchFromGitHub {
    owner = "Serivy";
    repo = "HG659-VOIP-Password";
    rev = "b114e3a7c9ae1f634cfb5f0be074da440cbba51c";
    sha256 = "sha256-xG06sk1d6hrMxD+xDSkGF/mfbI54fL47Vm9OG0qzWlc=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/hg659-voip-password}

    cp DecryptConfig.ps1 DecryptPassword.ps1 $out/share/hg659-voip-password

    makeWrapper ${powershell}/bin/pwsh $out/bin/hg659-decrypt-config \
      --set POWERSHELL_TELEMETRY_OPTOUT true \
      --add-flags "$out/share/hg659-voip-password/DecryptConfig.ps1"

    makeWrapper ${powershell}/bin/pwsh $out/bin/hg659-decrypt-password \
      --set POWERSHELL_TELEMETRY_OPTOUT true \
      --add-flags "$out/share/hg659-voip-password/DecryptPassword.ps1"

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/Serivy/HG659-VOIP-Password";
    platforms = powershell.meta.platforms;
  };
}
