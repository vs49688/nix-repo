{ config, lib, pkgs, ... }:
let
  homebrewPath = "/opt/homebrew";
in {
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    targets.darwin.defaults = {
      NSGlobalDomain = {
        # Dark mode
        AppleInterfaceStyle = "Dark";

        # Disable auto-correct
        NSAutomaticSpellingCorrectionEnabled = false;

        # Disable auto-capitalize
        NSAutomaticCapitalizationEnabled = false;

        # Disable smart quotes (use straight quotes for code)
        NSAutomaticQuoteSubstitutionEnabled = false;

        # Disable smart dashes
        NSAutomaticDashSubstitutionEnabled = false;

        # Disable auto-period (double-space inserts period)
        NSAutomaticPeriodSubstitutionEnabled = false;

        # Disable auto text completion
        NSAutomaticTextCompletionEnabled = false;

        # Small sidebar icons
        NSTableViewDefaultSizeMode = 1;

        # Show all file extensions
        AppleShowAllExtensions = true;

        # Save to local disk by default (not iCloud)
        NSDocumentSaveNewDocumentsToCloud = false;

        # Expand save and print dialogs by default
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
      };

      "Apple Global Domain" = {
        KeyRepeat        = 3;
        InitialKeyRepeat = 15;

        AppleICUForce12HourTime = 0;
        AppleICUForce24HourTime = 1;
      };

      "com.apple.dock" = {
        show-recents = false;

        # Small icons (27px) with subtle magnification (33px on hover)
        tilesize = 27;
        magnification = true;
        largesize = 33;

        # Don't rearrange Spaces based on recent use
        mru-spaces = false;

        # Don't enter Mission Control by dragging windows to top
        enterMissionControlByTopWindowDrag = false;

        # Enable App Expose gesture (3-finger swipe down)
        showAppExposeGestureEnabled = true;

        # Disable hot corners
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;

        wvous-tl-modifier = 0;
        wvous-tr-modifier = 0;
        wvous-bl-modifier = 0;
        wvous-br-modifier = 0;
      };

      "com.apple.WindowManager" = {
        # Disable click wallpaper to show desktop
        EnableStandardClickToShowDesktop = false;

        # Hide widgets on desktop
        StandardHideWidgets = true;
        StageManagerHideWidgets = true;

        # Disable window tiling by edge drag
        EnableTiledWindowMargins = false;
        EnableTilingByEdgeDrag = false;
        EnableTopTilingByEdgeDrag = false;
      };

      "com.apple.finder" = {
        DisableAllAnimations = true;

        # Show status bar and path bar
        ShowStatusBar = true;
        ShowPathbar = true;

        # Default to list view
        FXPreferredViewStyle = "Nlsv";

        # New Finder windows open to home directory
        NewWindowTarget = "PfHm";
        NewWindowTargetPath = "file://${config.home.homeDirectory}/";

        # Search current folder by default
        FXDefaultSearchScope = "SCcf";

        # Show hidden files (dotfiles)
        AppleShowAllFiles = false;

        # Show external drives and removable media on desktop
        ShowExternalHardDrivesOnDesktop = true;
        ShowRemovableMediaOnDesktop = true;

        FXInfoPanesExpanded = {
          General = true;
          OpenWith = true;
          Privileges = true;
        };
      };

      "com.apple.desktopservices" = {
        DSDontWriteUSBStores = true;
        DSDontWriteNetworkStores = true;
      };

      "com.apple.NetworkBrowser" = {
        BrowseAllInterfaces = true;
      };

      "com.apple.CrashReporter" = {
        DialogType = "notification";
      };

      "com.apple.TextEdit" = {
        RichText = 0;
      };
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

