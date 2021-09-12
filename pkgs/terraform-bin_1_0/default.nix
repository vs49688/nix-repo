{ stdenv, fetchzip }:
stdenv.mkDerivation rec {
  pname   = "terraform-bin";
  version = "1.0.6";

  src = fetchzip {
    url    = "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip";
    sha256 = "0g3cp9qk46dm8sq92jyz4s7cvhc9yvf8c7qx31k4xqls8xc1mhmk";
  };

  dontConfigure = true;
  dontBuild     = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mv terraform $out/bin
    chmod 0755 $out/bin/terraform

    runHook postInstall
  '';
}
