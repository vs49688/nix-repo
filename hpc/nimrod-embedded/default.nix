{ stdenv
, lib
, writeScript
, fetchurl
, coreutils
, gnutar
, nimrun
, installPrefix
, modulePath
, moduleName    ? "embedded-nimrod"
, moduleVersion ? "1.11.0"
}:
stdenv.mkDerivation rec {
  inherit nimrun;

  pname         = "nimrod-embedded";
  version       = "1.11.0";

  inherit installPrefix;
  inherit modulePath;
  inherit moduleName; # module load ${moduleName}
  inherit moduleVersion;

  rootDir       = "${installPrefix}/embedded-${moduleVersion}";
  nimrodHome    = "${rootDir}/opt/nimrod";
  javaHome      = "${rootDir}/opt/jvm/jdk";
  qpidHome      = "${rootDir}/opt/qpid";

  jdkTarball = fetchurl {
    url    = "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz";
    sha256 = "0irbfq52wlzxpvwrcnxy4s8qqh2g9m3icx54gisbfz03b38ylk3f";
  };

  qpidTarball = fetchurl {
    url    = "http://archive.apache.org/dist/qpid/broker-j/7.1.2/binaries/apache-qpid-broker-j-7.1.2-bin.tar.gz";
    sha256 = "1s8fwmffg7hlr7il1niyiff46kqibpabc402nhzykl9gxvkgdidi";
  };

  nimrodTarball = fetchurl {
    url    = "https://github.com/UQ-RCC/nimrodg/releases/download/${version}/nimrod-${version}.tar.gz";
    sha256 = "0b3xi0jdafgnjy5a4mlazhb2lajkh7kp6aiqpwp7457y861qm1kf";
  };

  modulefile      = ./modulefile;
  modulefile_lmod = ./modulefile.lua;

  buildInputs = [ coreutils gnutar ];

  nimexec = writeScript "nimexec" ''
    #!/bin/sh -e
    ##
    # Embedded Nimrod nimexec wrapper
    ##

    export MODULEPATH=${lib.strings.escapeShellArg modulePath}:$MODULEPATH
    module load "${moduleName}/${moduleVersion}" 2> /dev/null 1> /dev/null

    exec -a nimexec nimrun "$@"
  '';

  dontUnpack    = true;
  dontConfigure = true;

  buildPhase = ''
    # Nix puts some files in .
    mkdir -p build
    cd build

    mkdir -p lib/jvm/jdk opt/qpid opt/nimrod bin
    tar -C lib/jvm/jdk --strip-components=1 -xf $jdkTarball
    tar -C opt/qpid    --strip-components=2 -xf $qpidTarball
    tar -C opt/nimrod  --strip-components=1 -xf $nimrodTarball
    cp ${nimrun}/bin/nimrun bin
    cp ${nimexec} bin/nimexec

    substitute ${modulefile} modulefile      \
      --subst-var-by nimrod_version ${version}    \
      --subst-var-by root_dir       ${rootDir}    \
      --subst-var-by nimrod_home    ${nimrodHome} \
      --subst-var-by java_home      ${javaHome}   \
      --subst-var-by qpid_home      ${qpidHome}

    substitute ${modulefile_lmod} modulefile.lua \
      --subst-var-by nimrod_version ${version}        \
      --subst-var-by root_dir       ${rootDir}        \
      --subst-var-by nimrod_home    ${nimrodHome}     \
      --subst-var-by java_home      ${javaHome}       \
      --subst-var-by qpid_home      ${qpidHome}
  '';

  installPhase  = ''
    base=$(basename "${rootDir}")
    tar --transform "s/^/$base\//" -cf $out *
  '';

  # This needs to run on CentOS7
  dontFixup = true;
  dontStrip = true;
}