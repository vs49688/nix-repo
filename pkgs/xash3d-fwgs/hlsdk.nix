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
    version = "0-unstable-2026-06-14";
    rev = "8c5b2846c2448e2b063f358f041d565dc0f076b1";
    sha256 = "sha256-PgHmKPqRpPEkrxYq2EaKUpIYmQe8naLyWyALZFixdtw=";
  };

  bshift = makeSDK {
    name = "bshift";
    version = "0-unstable-2026-06-14";
    rev = "cd04b6190b234b27abc31dd992947af3842f6d24";
    sha256 = "sha256-t0gm4y3jdY+421w2Xyw7XkWA4UdkEbTxCJIU6o8Zsqg=";
  };

  dmc = makeSDK {
    name = "dmc";
    version = "0-unstable-2026-06-17";
    rev = "7e635fff071ee7eba863adb4cf311c6565c9fdaa";
    sha256 = "sha256-tMfB6v8PMbwKeuT8FEUKDBxFKtlSJ9f8QPUFd26Vxmk=";
  };

  gearbox = makeSDK {
    name = "gearbox";
    version = "0-unstable-2026-06-14";
    rev = "613eb55d5bcd257219c881297d1d43c1da4a7445";
    sha256 = "sha256-sMOlK3KeZzYNQstLeYOd2TND4ikd9M+3yAKVKOKE2tI=";
  };
}