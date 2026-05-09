{ stdenvNoCC
, lib
, requireFile
, callPackage
, sdks
}:
let
  makeGame = { src, sdk ? null, gamedir, gameName ? null, ... }@args: stdenvNoCC.mkDerivation(finalAttrs: {
    src = src.overrideAttrs(old: { allowSubstitutes = true; });

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/${finalAttrs.passthru.path}
      cp -R * $out/${finalAttrs.passthru.path}
    '' + (lib.optionalString (sdk != null) ''
      cp -R ${sdk}/*/* $out/${finalAttrs.passthru.path}
    '');

    passthru.gamedir = gamedir;
    passthru.gameName = gameName;
    passthru.sdk = sdk;
    passthru.path = "lib/xash3d/${gamedir}";
    passthru.iconPath = "${finalAttrs.passthru.path}/game.tga";
  } // (builtins.removeAttrs args ["src" "sdk" "gamedir" "gameName" ]));
in
{
  valve = makeGame {
    pname = "valve-gamedir";
    version = "15961492";

    src = requireFile {
      name = "gamedir-valve-15961492.tar.xz";
      message = "Please prefetch gamedir-valve-15961492.tar.xz into the Nix store";
      sha256 = "sha256-0Owagpp6nbthqHYUCjwFwjMprwbVdpdFoSh8z1C4SrE=";
    };

    sdk = sdks.valve;

    gamedir = "valve";
    gameName = "Half-Life";
  };

  valve_hd = makeGame {
    pname = "valve-hd-gamedir";
    version = "15961492";

    src = requireFile {
      name = "gamedir-valve-hd-15961492.tar.xz";
      message = "Please prefetch gamedir-valve-hd-15961492.tar.xz into the Nix store";
      sha256 = "sha256-xAq/CiBxTfv4KQvb0V6g2aH4GWPeAOeY1rrJQY04zp0=";
    };

    gamedir = "valve_hd";
  };

  bshift = makeGame {
    pname = "bshift-gamedir";
    version = "5424832";

    src = requireFile {
      name = "gamedir-bshift-5424832.tar.xz";
      message = "Please prefetch gamedir-bshift-5424832.tar.xz into the Nix store";
      sha256 = "sha256-IHr+2ol2OxY0E6UIkPtYNRE3e0hN9j5TmPn9wKXp43w=";
    };

    sdk = sdks.bshift;

    gamedir = "bshift";
    gameName = "Half-Life: Blue Shift";
  };

  bshift_hd = makeGame {
    pname = "bshift-hd-gamedir";
    version = "5424832";

    src = requireFile {
      name = "gamedir-bshift-hd-5424832.tar.xz";
      message = "Please prefetch gamedir-bshift-hd-5424832.tar.xz into the Nix store";
      sha256 = "sha256-v76RigVEGu/rp+LFNKJptNP3pdqEmPD8IcEpKNRlO0s=";
    };

    gamedir = "bshift_hd";
  };

  dmc = makeGame {
    pname = "dmc-gamedir";
    version = "5424794";

    src = requireFile {
      name = "gamedir-dmc-5424794.tar.xz";
      message = "Please prefetch gamedir-dmc-5424794.tar.xz into the Nix store";
      sha256 = "sha256-zu5JaA0/PJUx4t43BGOZjgc4lq5KqvWyp0NTTiyJFoI=";
    };

    sdk = sdks.dmc;

    gamedir = "dmc";
    gameName = "Deathmatch Classic";
  };

  gearbox = makeGame {
    pname = "gearbox-gamedir";
    version = "5429885";

    src = requireFile {
      name = "gamedir-gearbox-5429885.tar.xz";
      message = "Please prefetch gamedir-gearbox-5429885.tar.xz into the Nix store";
      sha256 = "sha256-1oYVxbDCex0JUWG9Er1+j+H/PwWlyjttMH7YciZwIvs=";
    };

    sdk = sdks.gearbox;

    gamedir = "gearbox";
    gameName = "Half-Life: Opposing Force";
  };

  gearbox_hd = makeGame {
    pname = "gearbox-hd-gamedir";
    version = "5429885";

    src = requireFile {
      name = "gamedir-gearbox-hd-5429885.tar.xz";
      message = "Please prefetch gamedir-gearbox-hd-5429885.tar.xz into the Nix store";
      sha256 = "sha256-YDtGF9Rdyc+nko8z8nG1rJJD4S0aCMwRf7oEATAR6mY=";
    };

    gamedir = "gearbox_hd";
  };

  cstrike = makeGame {
    pname = "cstrike-gamedir";
    version = "12934623";

    src = requireFile {
      name = "gamedir-cstrike-12934623.tar.xz";
      message = "Please prefetch gamedir-cstrike-12934623.tar.xz into the Nix store";
      sha256 = "sha256-LSzi7Ur5qtJH5pCAvhGFG/J/L1W+rky0G0NHlqsSc/I=";
    };

    gamedir = "cstrike";
    gameName = "Counter-Strike";
  };

  czero = makeGame {
    pname = "czero-gamedir";
    version = "12934630";

    src = requireFile {
      name = "gamedir-czero-12934630.tar.xz";
      message = "Please prefetch gamedir-czero-12934630.tar.xz into the Nix store";
      sha256 = "sha256-AJZSs/jxGngEuc2NXrBHvrBbVebibT0vGW1EU6Rj8X4=";
    };

    gamedir = "czero";
    gameName = "Condition Zero";
  };

  ricochet = makeGame {
    pname = "ricochet-gamedir";
    version = "5424813";

    src = requireFile {
      name = "gamedir-ricochet-5424813.tar.xz";
      message = "Please prefetch gamedir-ricochet-5424813.tar.xz into the Nix store";
      sha256 = "sha256-2B1krY30ZqjLD+ifWoBmQVfud+/XLIYCIXS/wjjzdRo=";
    };

    gamedir = "ricochet";
    gameName = "Ricochet";
  };

  tfc = makeGame {
    pname = "tfc-gamedir";
    version = "15961539";

    src = requireFile {
      name = "gamedir-tfc-15961539.tar.xz";
      message = "Please prefetch gamedir-tfc-15961539.tar.xz into the Nix store";
      sha256 = "sha256-3WT2/Y5KRCQDaLArC3aN1szU+/omekc29QCRAIgSRxE=";
    };

    gamedir = "tfc";
    gameName = "Team Fortress";
  };
}
