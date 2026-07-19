{ config, lib, pkgs, ... }:
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    programs.bash.enableVteIntegration = true;
    programs.bash.shellAliases = {
      # NB: cpupower is a kernel package, use whatever's in path.
      cfmon = "${pkgs.procps}/bin/watch -n1 -- cpupower -c all frequency-info -fm";
      cfperf = "sudo cpupower frequency-set -g performance";
      cfsave = "sudo cpupower frequency-set -g powersave";
    } // (lib.optionalAttrs (pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64) {
      #wine-ge = "${pkgs.wine-ge}/bin/wine";
    });

    home.sessionVariables = {
      WINEDLLOVERRIDES = "winemenubuilder.exe=d";
    };

    # Work around https://bugs.kde.org/show_bug.cgi?id=458085
    home.file.".gnupg/gpg-agent.conf".text = ''

      ###+++--- GPGConf ---+++###
      no-allow-external-cache
      ###+++--- GPGConf ---+++### Tue 25 Oct 2022 00:51:56 AEST
      # GPGConf edited this configuration file.
      # It will disable options before this marked block, but it will
      # never change anything below these lines.
    '';

    dconf.settings = {
      "org/gnome/desktop/privacy".remember-recent-files     = false;
      "org/gnome/desktop/privacy".remember-app-usage        = false;
      "org/gnome/desktop/privacy".recent-files-max-age      = 0;
      "org/gnome/desktop/privacy".send-software-usage-stats = false;
      "org/gnome/desktop/privacy".report-technical-problems = false;
    };

    ##
    # Configure file associations. Some of the defaults are insane.
    # e.g. Opening a inode/directory in audacious.
    #
    # NB: Home Manager symlinks ~/.config/mimeapps into the nix store.
    #     Caja will overwrite the symlink with an actual file. So don't.
    ##
    xdg.configFile."mimeapps.list".force = true; # Things always overwrite this...
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = let
      mediaPlayers    = [ "mpv.desktop" "vlc.desktop" ];
      webBrowsers     = [ "librewolf.desktop" "firefox.desktop" "chromium-browser.desktop" ];
      imageViewers    = [ "org.kde.gwenview.desktop" ];
      textEditors     = [ "org.kde.kwrite.desktop" "org.kde.kate.desktop" ];
      mailClients     = [ "thunderbird.desktop" ];
      pdfViewers      = [ "org.kde.okular.desktop" ];
      officeWriter    = [ "writer.desktop" ];
      officeCalc      = [ "calc.desktop" ];
      torrentClients  = [ "org.qbittorrent.qBittorrent.desktop" ];
      fileBrowsers    = [ "org.kde.dolphin.desktop" ];
      telegram        = [ "telegramdesktop.desktop" ];
      matrixClients   = [ "nheko.desktop" ];
      ebookViewers    = [ "com.github.johnfactotum.Foliate.desktop" ];
    in {
      ##
      # Text Formats
      ##
      "text/plain"                        = textEditors;
      "text/x-log"                        = textEditors;
      "text/x-c++src"                     = textEditors;
      "text/x-c++hdr"                     = textEditors;
      "application/x-desktop"             = textEditors;
      "application/xml"                   = textEditors;
      "application/x-wine-extension-ini"  = textEditors;
      "audio/x-mpegurl"                   = textEditors; # m3u
      "application/vnd.apple.mpegurl"     = textEditors; # m3u8
      "application/x-cue"                 = textEditors;

      ##
      # Multimedia Formats
      ##
      "audio/flac"          = mediaPlayers;
      "audio/mpeg"          = mediaPlayers;
      "audio/mp4"           = mediaPlayers;
      "audio/ogg"           = mediaPlayers;
      "audio/x-wav"         = mediaPlayers;
      "audio/x-vorbis+ogg"  = mediaPlayers;
      "audio/x-tun"         = mediaPlayers;
      "audio/x-cvg"         = mediaPlayers;

      "video/x-flv"       = mediaPlayers;
      "video/mp4"         = mediaPlayers;
      "video/mpeg"        = mediaPlayers;
      "video/mp2t"        = mediaPlayers;
      "video/msvideo"     = mediaPlayers;
      "video/quicktime"   = mediaPlayers;
      "video/webm"        = mediaPlayers;
      "video/x-avi"       = mediaPlayers;
      "video/x-brp"       = mediaPlayers;
      "video/x-matroska"  = mediaPlayers;
      "video/x-mpeg"      = mediaPlayers;
      "video/x-ogm+ogg"   = mediaPlayers;
      "video/x-ms-wmv"    = mediaPlayers;

      ##
      # Image Formats
      ##
      "image/jpeg"                = imageViewers;
      "image/png"                 = imageViewers;
      "image/gif"                 = imageViewers;
      "image/bmp"                 = imageViewers;
      "image/tiff"                = imageViewers;
      "image/vnd.microsoft.icon"  = imageViewers;

      ##
      # HTML-related
      ##
      "text/html"                 = webBrowsers;
      "x-scheme-handler/http"     = webBrowsers;
      "x-scheme-handler/https"    = webBrowsers;
      "x-scheme-handler/about"    = webBrowsers;
      "x-scheme-handler/unknown"  = webBrowsers;
      "application/xhtml+xml"     = webBrowsers;
      "application/x-extension-html" = webBrowsers;

      ##
      # Misc
      ##
      "application/pdf"          = pdfViewers;
      "x-scheme-handler/tg"      = telegram;
      "x-scheme-handler/element" = matrixClients;
      "x-scheme-handler/matrix"  = matrixClients;
      "inode/directory"          = fileBrowsers;

      "application/epub+zip"     = ebookViewers;

      ##
      # Mail Types
      ##
      "x-scheme-handler/mailto"     = mailClients;
      "message/rfc822"              = mailClients;
      "application/x-extension-eml" = mailClients;

      ##
      # Torrent Types
      ##
      "application/x-bittorrent"    = torrentClients;
      "x-scheme-handler/magnet"     = torrentClients;

      ##
      # Office Formats
      ##
      "application/msword"          = officeWriter;
      "application/rtf"             = officeWriter;
      "application/vnd.ms-excel"    = officeCalc;

      "application/vnd.oasis.opendocument.spreadsheet"  = officeCalc;
      "application/vnd.oasis.opendocument.text"         = officeWriter;

      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = officeCalc;
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = officeWriter;
    };

    xdg.dataFile."mime/packages/audio-x-tun.xml" = {
      source = ./audio-x-tun.xml;
    };

    xdg.dataFile."mime/packages/audio-x-cvg.xml" = {
      source = ./audio-x-cvg.xml;
    };

    xdg.dataFile."mime/packages/video-x-brp.xml" = {
      source = ./video-x-brp.xml;
    };


    ##
    # Configure EasyEffects.
    # - Most machines have shitty speakers so just do this for all.
    ##
    services.easyeffects.enable = lib.mkDefault true;
    services.easyeffects.preset = "Advanced Auto Gain";
    services.easyeffects.extraPresets = {
      "Advanced Auto Gain" = builtins.fromJSON (builtins.readFile ./AdvancedAutoGain.json);
      thinkpad-unsuck = builtins.fromJSON (builtins.readFile ./thinkpad-unsuck.json);
    };

    qt.kde.settings = {
      kdeglobals = {
        KDE = {
          LookAndFeelPackage = "org.kde.breezedark.desktop";
        };

        General = {
          TerminalApplication = "alacritty";
          TerminalService = "Alacritty.desktop";
        };
      };

      powerdevilrc = {
        General = {
          # I have never seen a case of this working correctly.
          pausePlayersOnSuspend = false;
        };

        AC = {
          Display = {
            TurnOffDisplayIdleTimeoutSec = -1;
            TurnOffDisplayWhenIdle = false;
          };

          SuspendAndShutdown = {
            InhibitLidActionWhenExternalMonitorPresent = false;
          };
        };
      };

      kwriterc = {
        General = {
          "Show welcome view for new window" = false;
        };
      };

      knetwalkrc = {
        General.PlaySounds = false;
        KgDifficulty.Level = "Very Hard";
      };

      kwinrc = {
        Wayland.EnablePrimarySelection = false;
        Xwayland.Scale = 1;

        NightColor = {
          Active = true;
          Mode = "Constant";
        };

        Effect-overview.BorderActivate = 9;

        MouseBindings.CommandAll1 = "Activate, raise and move";
      };

      kxkbrc = {
        Layout = {
          Use = true;
          LayoutList = "au,ru";
        };
      };

      kglobalshortcutsrc = {
        "KDE Keyboard Layout Switcher" = {
          "Switch to Next Keyboard Layout" = "Ctrl+Alt+Space,Meta+Alt+K,Switch to Next Keyboard Layout";
        };

        services = {
          "Alacritty.desktop" = {
            New = "Ctrl+Alt+T";
          };

          "org.kde.konsole.desktop" = {
            _launch = "none";
          };
        };
      };

      krunnerrc = {
        Plugins = {
          baloosearchEnabled = false;
        };
      };

      baloofilerc = {
        "Basic Settings" = {
          "Indexing-Enabled" = false;
        };
      };

      # MORNINGSTAR
      kcminputrc.Libinput."1267"."12693"."ELAN0676:00 04F3:3195 Touchpad" = {
        DisableWhileTyping = false;
        NaturalScroll = true;
      };
    };
  };
}
