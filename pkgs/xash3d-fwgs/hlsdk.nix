{ stdenv, fetchFromGitHub, cmake, lib }:
let
  makeSDK = { name, version, rev, sha256 ? lib.fakeHash }: stdenv.mkDerivation {
    inherit version;

    pname = "hlsdk-${name}";

    src = fetchFromGitHub {
      inherit rev sha256;
      owner = "FWGS";
      repo = "hlsdk-portable";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [ cmake ];

    cmakeFlags = [
      "-D64BIT=ON"
    ];
  };
in {
  inherit makeSDK;

  valve = makeSDK {
    name = "valve";
    version = "unstable-2024-08-21";
    rev = "f1c430ae1d33b946bb86101b806d927d9cf728ad";
    sha256 = "sha256-NQ7yjIdFt3ZlWg3SxaQQy/chxiIv837io2ocQKR3i6w=";
  };

  bshift = makeSDK {
    name = "bshift";
    version = "unstable-2024-08-21";
    rev = "9f490a5a07da294d1adb050687fd443fb065fdc3";
    sha256 = "sha256-VSMJ+XEfPIoMzB8j/VZnv2HfCXqhqK/01MtBdDyE0PE=";
  };

  dmc = makeSDK {
    name = "dmc";
    version = "unstable-2024-08-21";
    rev = "01474b39612f657b1e3aaad19ba0387f77004d48";
    sha256 = "sha256-UYOH9yoTDiKViw+X5Z4QJ0NxeVseMw/7Tn9K5d5ihnA=";
  };

  gearbox = makeSDK {
    name = "gearbox";
    version = "unstable-2024-08-21";
    rev = "66ffcb80ba1bbb75edbf13875b85a3bfc0fc11da";
    sha256 = "sha256-zERl8AIrorycebpp6dTyMalSG+DhqQgZHIiL8RrgqD8=";
  };
}