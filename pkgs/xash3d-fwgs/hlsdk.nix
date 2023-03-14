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
    version = "unstable-2023-03-02";
    rev = "3329d49dca431987a20f9e6e2eac140851c5cd91";
    sha256 = "sha256-u1qD2YgP+b11Rlx7IfOejvWuVGIj05FFwUw21hyYz8Y=";
  };

  bshift = makeSDK {
    name = "bshift";
    version = "unstable-2023-03-02";
    rev = "aea9499bd2b1d662cd71efeaad99d2b26f581d5e";
    sha256 = "sha256-eDLxeTridfBSbMq0jyaLXb03wmFnu102y/FpKgO2Q4E=";
  };

  dmc = makeSDK {
    name = "dmc";
    version = "unstable-2023-03-11";
    rev = "e4f5e3d9d38b49a4da4aee3f3bad7c48dcc4c510";
    sha256 = "sha256-0ts6n9+TWxuEa5cML7T/0XjEX8Z+dTLvQU2JJNnE6cQ=";
  };

  gearbox = makeSDK {
    name = "gearbox";
    version = "unstable-2023-03-11";
    rev = "942500309b11bdd17e72d111bf76ba303d36b6dd";
    sha256 = "sha256-6dcURN2DKy3jYOm1Ld1pwx+A9X2aD6gJ2mHvbQCCqJU=";
  };
}