{ config, lib, pkgs, ... }:
let
  homebrewPath = "/opt/homebrew";
in {
  config = lib.mkIf pkgs.stdenv.isDarwin {
    targets.darwin.defaults = {
      "Apple Global Domain" = {
        KeyRepeat        = 3;
        InitialKeyRepeat = 15;
      };

      "com.apple.dock".show-recents = false;
    };

    home.file.".hammerspoon".source = ./hammerspoon;

    home.file."Library/KeyBindings/DefaultKeyBinding.Dict" = {
      source = ./DefaultKeyBinding.Dict;
    };

    programs.bash.shellAliases = {
      l  = "${pkgs.coreutils}/bin/ls -alh";
      ll = "${pkgs.coreutils}/bin/ls -l";
      ls = "${pkgs.coreutils}/bin/ls --color=tty";
    };

    programs.bash.initExtra = ''
      # This seems grotty...
      if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
        . $HOME/.nix-profile/etc/profile.d/nix.sh;
      fi

      eval "$(${pkgs.coreutils}/bin/dircolors -b)"

      if [ -x ${homebrewPath}/bin/brew ]; then
        eval "$(${homebrewPath}/bin/brew shellenv)"
      fi
    '';
  };
}

