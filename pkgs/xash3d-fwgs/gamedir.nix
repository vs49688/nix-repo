{ stdenv, lib, requireFile, xash3d-sdks }:
let
  makeGame = { src, sdk ? null, gamedir, gameName ? null, ... }@args: stdenv.mkDerivation ({
    src = src.overrideAttrs(old: { allowSubstitutes = true; });

    dontBuild = true;

    installPhase = ''
      mkdir -p $out
      cp -R * $out
    '' + (lib.optionalString (sdk != null) ''
      cp -R ${sdk}/*/* $out/
    '');

    passthru.gamedir = gamedir;
    passthru.gameName = gameName;
  } // (builtins.removeAttrs args ["src" "sdk" "gamedir" "gameName" ]));
in
{
  valve = makeGame {
    pname = "valve-gamedir";
    version = "unstable-2023-03-05";

    src = requireFile {
      name = "valve.tar";
      message = "Please prefetch valve.tar into the Nix store";
      sha256 = "sha256-AG6ZYcOtKd1WEVS3fJ8ZYmlfpwQeg7v830z2JYkBdVA=";
    };

    sdk = xash3d-sdks.valve;

    gamedir = "valve";
    gameName = "Half-Life";
  };

  valve_hd = makeGame {
    pname = "valve-hd-gamedir";
    version = "unstable-2023-03-05";

    src = requireFile {
      name = "valve_hd.tar";
      message = "Please prefetch valve_hd.tar into the Nix store";
      sha256 = "sha256-DCHy42EUuX/UGz93AqLNzlS8GHyRsLepCE4jNwv9vgE=";
    };

    gamedir = "valve_hd";
  };

  bshift = makeGame {
    pname = "bshift-gamedir";
    version = "unstable-2023-03-05";

    src = requireFile {
      name = "bshift.tar";
      message = "Please prefetch bshift.tar into the Nix store";
      sha256 = "sha256-0lv1rrs1t6SBNLFgfzLzRLJ8jXWScILCghsLQ7he3ck=";
    };

    sdk = xash3d-sdks.bshift;

    gamedir = "bshift";
    gameName = "Half-Life: Blue Shift";
  };

  bshift_hd = makeGame {
    pname = "bshift-hd-gamedir";
    version = "unstable-2023-03-05";

    src = requireFile {
      name = "bshift_hd.tar";
      message = "Please prefetch bshift_hd.tar into the Nix store";
      sha256 = "sha256-GAi6hNUSzcccadnaDpVBFQulAy2TpHEJeuvLINfceqM=";
    };

    gamedir = "bshift_hd";
  };

  dmc = makeGame {
    pname = "dmc-gamedir";
    version = "unstable-2023-03-05";

    src = requireFile {
      name = "dmc.tar";
      message = "Please prefetch dmc.tar into the Nix store";
      sha256 = "sha256-DQ/CI4gdT4gjlJplexzmn6YEtmHheULhEDUa+ohme9c=";
    };

    sdk = xash3d-sdks.dmc;

    gamedir = "dmc";
    gameName = "Deathmatch Classic";
  };

  gearbox = makeGame {
    pname = "gearbox-gamedir";
    version = "unstable-2023-03-05";

    src = requireFile {
      name = "gearbox.tar";
      message = "Please prefetch gearbox.tar into the Nix store";
      sha256 = "sha256-IgjyeDbVabR06Ubgs01ma+BR0inoFQAv9sEAC1SLRNc=";
    };

    sdk = xash3d-sdks.gearbox;

    gamedir = "gearbox";
    gameName = "Half-Life: Opposing Force";
  };

  gearbox_hd = makeGame {
    pname = "gearbox-hd-gamedir";
    version = "unstable-2023-03-05";

    src = requireFile {
      name = "gearbox_hd.tar";
      message = "Please prefetch gearbox_hd.tar into the Nix store";
      sha256 = "sha256-Zm9/UJJw8j+F6QeWoOltuyLFt6kaTNEYf+kv7+/605g=";
    };

    gamedir = "gearbox_hd";
  };
}
