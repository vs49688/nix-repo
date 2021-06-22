{ stdenv, lib, fetchurl, makeWrapper, autoPatchelfHook
, openssl, zlib, libaudit, tcl, tk, tcllib, xorg, libtool, linux-pam
}:
let
  tclLibraries = [ tcllib tk ];
  tclLibPaths = lib.concatStringsSep " "
    (map (p: "${p}/lib/${p.libPrefix}") tclLibraries);
in
stdenv.mkDerivation rec {
  pname   = "globusconnectpersonal";
  version = "3.1.5";

  src = fetchurl {
    url    = "https://downloads.globus.org/globus-connect-personal/v3/linux/stable/globusconnectpersonal-${version}.tgz";
    sha256 = "0cxf0vprpfhy9gh3zgs94h715w2qsk5bpfxsfc4xb6k8jq4n878l";
  };

  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    openssl           # For libssl.so.1.1, libcrypto.so.1.1
    zlib              # For libz.so.1
    libaudit          # For libaudit.so.1
    libtool           # For libltdl.so.7
    linux-pam         # For libpam.so.0
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,globus}

    rm -f tclkit gt_amd64/lib/lib{crypto,ltdl,pam{,c},ssl,z}.*
    mv * $out/globus
    ln -s ${tcl}/bin/tclsh $out/globus/tclkit

    makeWrapper $out/globus/globusconnectpersonal $out/bin/globusconnectpersonal \
          --prefix PATH : ${lib.makeBinPath [ xorg.xhost ]} \
          --set TCLLIBPATH "${tclLibPaths}"

    ln -s $out/bin/globusconnectpersonal $out/bin/globusconnect

    runHook postInstall
  '';

  meta = with lib; {
    description = "Globus Connect Personal turns your laptop or other personal computer into a Globus endpoint with just a few clicks";
    homepage    = "https://www.globus.org/globus-connect-personal";
    license     = licenses.unfree;
    platforms   = [ "x86_64-linux" ];
  };
}
