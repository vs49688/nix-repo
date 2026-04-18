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

  valve = (makeSDK {
    name = "valve";
    version = "unstable-2026-03-26-0";
    rev = "ae84bfc0c3598fcff605a7b3bb963abe8ec3e295";
    sha256 = "sha256-UAEFUr2BqOXx3/MklJzELXdUm7EKUttiJE7IjHZ8rHE=";
  }).overrideAttrs(old: {
    patches = [
      ./0001-dlls-player-add-item_longjump-to-impulse-101.patch
      ./0002-cl_dll-in_camera-allow-thirdperson-in-multiplayer.patch
      ./0001-dlls-multiplay_gamerules-precache-player-model-on-co.patch
    ];
  });

  bshift = makeSDK {
    name = "bshift";
    version = "unstable-2026-03-26-0";
    rev = "df5c27283d4c7409f54aa63bf15143e5598ce02d";
    sha256 = "sha256-PqlzwY7z8R8uRZdCtQ6XK+sN6bnbrsX/K8uXBHonPb8=";
  };

  dmc = makeSDK {
    name = "dmc";
    version = "unstable-2026-03-26-0";
    rev = "a205490557c2ac1c317fd981d0c92bfc99b3b886";
    sha256 = "sha256-s1HsvTbWPXjcjhXDkFCkDs3LNPVrBmV55uZt133PE/o=";
  };

  gearbox = makeSDK {
    name = "gearbox";
    version = "unstable-2026-03-26-0";
    rev = "f7ce421fde685fa252a003189d131dd4e5d2d8c4";
    sha256 = "sha256-g2Lqrx7y41tEJTCHAiziFGQJE3e6taI6stvHLZ0K0Ug=";
  };
}