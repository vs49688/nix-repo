{ stdenv, fetchurl }:
stdenv.mkDerivation rec {
  pname   = "ipp";
  version = "1.1.2";

  src = fetchurl {
    url    = "https://github.com/UQ-RCC/ipp/releases/download/${version}/ipp-${version}.tar.gz";
    sha256 = "1fpynsys8pjh4sww9i1ibc8rq950k0l5cfq5c8vrl751nn92059q";
  };

  dontConfigure = true;
  dontBuild     = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/${pname}
    mv * $out/share/${pname}
    find $out/share/${pname} -type d -print0 | xargs -0 chmod 0755
    find $out/share/${pname} -type f -print0 | xargs -0 chmod 0644

    runHook postInstall
  '';
}