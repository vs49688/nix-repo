{ stdenv, lib, cmake, fetchFromGitHub, openssl, writeText }:
stdenv.mkDerivation rec {
  pname    = "nimrun";
  # Not technically the version, just a placeholder
  version = "1.0.0";

  src = fetchFromGitHub {
    owner  = "UQ-RCC";
    repo   = "nimrod-embedded";
    rev    = "d8acd7776352cc8b770b347a824efed77a419579";
    sha256 = "1jz904k3fsv3l3z7n2isf89sxhy9lzd35pxdwcjk1wsvw5wnvdcd";
  };

  sourceRoot = "source/nimrun";

  patches = [
    (writeText "optional.patch" ''
--- a/nimrun.cpp
+++ b/nimrun.cpp
@@ -28,6 +28,7 @@
 #include <iomanip>
 #include <fstream>
 #include <iostream>
+#include <optional>
 #include "config.h"
 #include "nimrun.hpp"
'')
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs       = [ openssl.dev ];
  cmakeFlags        = [
    "-DCMAKE_EXE_LINKER_FLAGS=\"-static-libstdc++\""
    "-DGIT_HASH=${src.rev}"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp nimrun $out/bin
  '';

  meta = with lib; {
    description = "Nimrod/G Embedded Launch Utility";
    homepage    = "https://github.com/UQ-RCC/nimrod-embedded";
    platforms   = platforms.all;
    license     = licenses.asl20;
  };
}
