{ stdenvNoCC, mingwPkgs }:
let
  targetPrefix = mingwStdenv.cc.targetPrefix;

  mingwStdenv = mingwPkgs.stdenv.override {
    cc = mingwPkgs.stdenv.cc.override({
      # https://github.com/NixOS/nixpkgs/issues/156343
      extraBuildCommands = ''
        printf '%s' '-L${mingwPkgs.windows.mcfgthreads}/lib' >> $out/nix-support/cc-ldflags
        printf '%s' '-I${mingwPkgs.windows.mcfgthreads.dev}/include' >> $out/nix-support/cc-cflags
      '';
    });
  };
in mingwStdenv.cc
