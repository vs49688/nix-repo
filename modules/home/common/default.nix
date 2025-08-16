{ config, lib, pkgs, ... }:
{
  options.common = with lib; {
    gitName = mkOption {
      type = types.str;
    };

    gitEmail = mkOption {
      type = types.str;
    };

    gitSigningKey = mkOption {
      type = types.str;
    };

    sshDefaultKey = mkOption {
      type = types.str;
    };

    goPrivate = mkOption {
      type = types.listOf types.str;
    };
  };

  config = {
    manual.html.enable = false;
    manual.json.enable = false;
    manual.manpages.enable = true;
    news.display = "silent";

    home.packages = with pkgs; [
      bashInteractive
      coreutils
      findutils
      most
      htop
      tmux
      gnugrep
      gnused
      gnutar
      gnumake
      xz
      gzip
      jq
      jless
      imagemagick
      gopass
      bat
      # git is handled below

      openrussian-cli

    ] ++ (if pkgs.stdenv.isDarwin then [
      ffmpeg
    ] else [
      ffmpeg-full
    ]);

    home.sessionVariables.GPG_TTY   = "$(tty)";
    home.sessionVariables.GOPRIVATE = (builtins.concatStringsSep "," config.common.goPrivate);
    # home.sessionVariables.GOPROXY   = "direct";
    home.sessionVariables.EDITOR    = "${config.programs.neovim.package}/bin/nvim";
    home.sessionVariables.MANPAGER  = "${pkgs.most}/bin/most";
    home.sessionVariables.NIXOS_OZONE_WL = "1";

    home.sessionPath      = [ "$HOME/.local/bin" ];

    programs.bash = {
      enable               = true;
      historyControl       = [ "erasedups" "ignoredups" "ignorespace" ];
      historyIgnore        = [ "youtube-dl" "yt-dlp" ];

      shellAliases = {
        # https://winsmarts.com/decode-jwt-token-on-terminal-d005ba6c5aa1?gi=a023ba75863f
        # Decode JWT header
        jwtdech = "${pkgs.jq}/bin/jq -R 'split(\".\") | .[0] | @base64d | fromjson'";
        # Decode JWT payload
        jwtdecp = "${pkgs.jq}/bin/jq -R 'split(\".\") | .[1] | @base64d | fromjson'";

        grep    = "${pkgs.gnugrep}/bin/grep --color";
        fixeng  = "export LANG=en_AU.UTF-8; export LANGUAGE=en_AU:en_GB:en";

        webp2png = "for i in *.webp; do ${pkgs.imagemagick}/bin/convert \"$i\" \"\${i::-5}.png\"; done";

        nix-build-derivation = "nix-build -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'";

        dnuke = "docker ps --format '{{ .ID }}' | xargs -r -- docker stop && docker ps -a --format '{{ .ID }}' | xargs -r -- docker rm; docker volume prune -f; docker network prune -f";

        ffconfigure = "grep FFMPEG_CONFIGURATION config.h | sed -E 's/^#define\\s+FFMPEG_CONFIGURATION\\s+\"(.+)\"$/\\1/g' | xargs ./configure";

        cqr = "${pkgs.qrencode}/bin/qrencode -t UTF8";

        baconv = "${pkgs.python3}/bin/python3 -c 'import sys; print([ord(i) for i in sys.stdin.read()])'";

        rain = "${pkgs.sox}/bin/play -t sl -r48000 -c2 - synth -1 pinknoise tremolo .1 40 < /dev/zero";

        # Can also use gst-launch-1.0 audiotestsrc wave=5 '!' audiocheblimit mode=low-pass cutoff=120 '!' pulsesink
        enterprise = "${pkgs.sox}/bin/play -n -c1 synth whitenoise lowpass -1 120 lowpass -1 120 lowpass -1 120 gain +14";
      };

      initExtra = ''
        function orf() { [[ $# == 1 ]] && ${pkgs.findutils}/bin/find "$1" -print0 -type f | ${pkgs.coreutils}/bin/shuf -z -n 1 | xargs -0 ${pkgs.xdg-utils}/bin/xdg-open  || echo 'Usage: orf <path>'; }

        # https://github.com/nix-community/home-manager/issues/1011
        [[ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]] && . ~/.nix-profile/etc/profile.d/hm-session-vars.sh

        function color_my_prompt {
            if [ $EUID = 0 ]; then
                local __colour="\[\033[01;31m\]"
            else
                local __colour="\[\033[01;32m\]"
            fi

            local __user_and_host="\u@\h"
            local __cur_location="\[\033[01;34m\]\w"
            local __git_branch_color="\[\033[31m\]"
            local __git_branch='$(${pkgs.gitMinimal}/bin/git branch 2> /dev/null | grep -e ^* | sed -E  s/^\\\\\*\ \(.+\)$/\(\\\\\1\)\ /)'
            #local __git_branch="(\$(${pkgs.gitMinimal}/bin/git rev-parse --abbrev-ref HEAD 2>/dev/null)) "
            local __prompt_tail="\[\033[35m\]\\$"
            local __last_color="\[\033[00m\]"
            local __prompt_start="$__colour[$__user_and_host:$__cur_location$__colour]"

            export PS1="$__prompt_start $__git_branch_color$__git_branch$__prompt_tail$__last_color "
        }
        color_my_prompt
      '';
    };

    programs.alacritty = {
      enable = true;
      settings = {
        # KDE Breeze (Ported from Konsole)
        colors = {
          primary = {
            background = "#232627";
            foreground = "#fcfcfc";

            dim_foreground    = "#eff0f1";
            bright_foreground = "#ffffff";
          };

          normal = {
            black   = "#232627";
            red     = "#ed1515";
            green   = "#11d116";
            yellow  = "#f67400";
            blue    = "#1d99f3";
            magenta = "#9b59b6";
            cyan    = "#1abc9c";
            white   = "#fcfcfc";
          };

          bright = {
            black   = "#7f8c8d";
            red     = "#c0392b";
            green   = "#1cdc9a";
            yellow  = "#fdbc4b";
            blue    = "#3daee9";
            magenta = "#8e44ad";
            cyan    = "#16a085";
            white   = "#ffffff";
          };

          dim = {
            black   = "#31363b";
            red     = "#783228";
            green   = "#17a262";
            yellow  = "#b65619";
            blue    = "#1b668f";
            magenta = "#614a73";
            cyan    = "#186c60";
            white   = "#63686d";
          };
        };

        # https://github.com/alacritty/alacritty/issues/2058#issuecomment-955007592
        hints.enabled = [
          {
            regex = ''(ipfs:|ipns:|magnet:|mailto:|gemini:|gopher:|https:|http:|news:|file:|git:|ssh:|ftp:)[^\u0000-\u001f\u007f-\u009F<>"\\s{-}\\^⟨⟩`]+'';
            command = (if pkgs.stdenv.isDarwin then "open" else "xdg-open");
            post_processing = true;
            mouse.enabled = true;
            mouse.mods = "Control";
          }
        ];
      };
    };

    programs.neovim = {
      enable = true;
      
      extraConfig = ''
        set tabstop=4
        set shiftwidth=4
        set expandtab
        set mouse=
        
        syntax on
      '';
      
      withNodeJs  = false;
      withPython3 = false;
      withRuby    = false;
      viAlias     = true;
      vimAlias    = true;
    };

    programs.git = {
      enable    = true;
      package   = pkgs.gitAndTools.gitFull;
      userName  = config.common.gitName;
      userEmail = config.common.gitEmail;
      signing.key = config.common.gitSigningKey;
      signing.signByDefault = true;
      lfs.enable = true;

      aliases = {
        adog   = "log --all --decorate --oneline --graph";
        statsu = "status";
        ffsend = "send-email --to=ffmpeg-devel@ffmpeg.org --confirm=always --suppress-cc=self";
        cad    = "commit --amend --date=now";
        wip    = "commit -m wip";
      };

      extraConfig = {
        pull = { rebase = true; };

        rebase.autosquash = true;

        # It'll be "main" over my dead body
        init = { defaultBranch = "master"; };

        diff = { gpg = { textconv = "gpg --no-tty --decrypt"; }; };

        url = {
          "ssh://git@github.com/" = { insteadOf = "https://github.com/"; };
          "ssh://git@codeberg.org/" = { insteadOf = "https://codeberg.org/"; };
          "ssh://git@git.vs49688.net/" = { insteadOf = "https://git.vs49688.net/"; };
        };

        advice = { skippedCherryPicks = false; };
      };
    };

    programs.ssh.enable = true;
    programs.ssh.serverAliveInterval = 5;
    programs.ssh.serverAliveCountMax = 15;
    programs.ssh.extraConfig = ''
      IdentitiesOnly yes
    '';
    programs.ssh.matchBlocks = {
      "github.com" = { user = "git"; identityFile = config.common.sshDefaultKey; };
      "codeberg.org" = { user = "git"; identityFile = config.common.sshDefaultKey; };
    };

    xdg.configFile."mpv/mpv.conf".text = ''
      loop=yes
      x11-bypass-compositor=no
      # audio-pitch-correction=no
      # af-add=scaletempo=speed=both
      # no-audio-display
      hwdec=yes
      no-keepaspect-window
    '';

    home.stateVersion = lib.mkDefault "21.11";
  };
}
