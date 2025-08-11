{ config, pkgs, lib, ... }:
let
  isStable = lib.versionOlder config.system.nixos.version "25.05";
in
{
  boot.kernelParams = [
    "preempt=full"
  ];

  environment.variables = {
    QT_LOGGING_RULES = "*.debug=false;qt.qpa.*=false";
  };

  programs.virt-manager.enable = lib.mkDefault config.virtualisation.libvirtd.enable;

  # programs.k3b.enable = lib.mkDefault true;
  programs.kclock.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    # Web Browsers
    # firefox is handled by programs.firefox.enable.
    ungoogled-chromium

    # "Office" Packages
    libreoffice
    xournalpp
    thunderbird
    remmina
    simple-scan
    foliate

    # Comms
    nheko
    tdesktop

    # Graphics
    gimp
    inkscape

    # Audio/Video
    audacious
    audacity
    vlc
    supersonic
    supersonic-wayland
    mpv
    pavucontrol
    qpwgraph

    # Misc
    keepassxc
    otpclient

    # CLI Tools
    yt-dlp
    ffmpeg-full
    gopass
    imagemagick

    # Administrative Packages
    qdirstat
    gparted
    x11vnc
    glxinfo
  ] ++ (with kdePackages; [
    kate
    ark
    kleopatra
    marble
    krdc
    kfind
    kcolorchooser
    kcharselect
    kolourpaint
    kompare
    skanlite
    kget
    konqueror
    krfb
    okteta
    kmplot
    kweather
    #kwave # Bad
    kruler
    kdebugsettings
    ksystemlog
    keditbookmarks

    kshisen
    ksquares
    kspaceduel
    kapman
    kblocks
    ksudoku
    katomic
    kbounce
    klines
    #ktouch # Bad
    kmines
    kbreakout
    bovo
    bomber
    granatier
    kblackbox
    kolf
    knights
    knetwalk
    kgeography
    kpat

    digikam
    exiftool

    partitionmanager

    # For KInfoCenter to work
    vulkan-tools
    wayland-utils
    xorg.xdpyinfo
    aha
    clinfo

    xboomer
  ]);

  programs.dconf.enable = lib.mkDefault true;

  programs.cdemu.gui = lib.mkDefault true;

  networking.networkmanager.enable = lib.mkDefault true;

  ##
  # Use pipewire as the default audio device.
  # It defaults to ALSA otherwise and stutters.
  ##
  environment.etc."mpv/mpv.conf".text = lib.optionalString config.services.pipewire.enable ''
    audio-device=pipewire
    pipewire-buffer=native
  '';

  security.rtkit.enable = lib.mkDefault true;

  ##
  # Disabled by default for now, but configured.
  ##
  services.pipewire = {
    enable            = lib.mkDefault true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    jack.enable       = true;
  };

  hardware.graphics.enable32Bit = lib.mkDefault config.hardware.graphics.enable;

  services.geoclue2.enable = lib.mkDefault true;

  fonts.fontconfig.useEmbeddedBitmaps = true;
  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-monochrome-emoji
    noto-fonts-color-emoji
    twemoji-color-font

    terminus_font
    terminus_font_ttf
    corefonts
    vistafonts
    fira-code
    fira-code-symbols
    cm_unicode
  ];

  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";

  # Enable touchpad support.
  services.libinput.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = lib.mkDefault true;
  services.desktopManager.plasma6.enable = true;

  nixpkgs.config.firefox.wrapperConfig.enablePlasmaBrowserIntegration = lib.mkForce false;

  programs.firefox.enable = lib.mkDefault true;
  programs.firefox.policies = {
    CaptivePortal = false;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableTelemetry = true;
    DisableProfileRefresh = true;
    NoDefaultBookmarks = true;

    FirefoxHome = {
      Search = true;
      TopSites = true;
      SponsoredTopSites = false;
      Highlights = false;
      Pocket = false;
      SponsoredPocket = false;
      Snippets = false;
      Locked = false;
    };

    FirefoxSuggest = {
      WebSuggestions = false;
      SponsoredSuggestions = false;
      ImproveSuggest = false;
      Locked = true;
    };

    UserMessaging = {
      WhatsNew = false;
      ExtensionRecommendations = false;
      FeatureRecommendations = false;
      UrlbarInterventions = false;
      SkipOnboarding = true;
      MoreFromMozilla = false;
      Locked = true;
    };
  };

  programs.firefox.preferences = {
    # NB: A good reference:
    # https://support.mozilla.org/en-US/questions/1325101

    # Show the extended validation info.
    # NB: This has been removed in Firefox 100+
    "security.identityblock.show_extended_validation" = true;

    # Show HTTP sites as insecure.
    "security.insecure_connection_text.enable" = true;

    # Disable Telemetry. Done above, but do it again because paranoia.
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "browser.ping-centre.telemetry" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;

    # Disable Normandy
    "app.normandy.enabled" = false;
    "app.normandy.user_id" = "00000000-0000-0000-0000-000000000000";
    "app.normandy.api_url" = "";
    "app.normandy.first_run" = false;

    "app.shield.optoutstudies.enabled" = false;

    # Disable "Firefox View", literally no one asked for this.
    "browser.tabs.firefox-view" = false;

    # Disable Pocket.
    "extensions.pocket.enabled" = false;

    # Disable automatic crash report submission.
    "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

    # Don't suggest extensions.
    "extensions.htmlaboutaddons.recommendations.enabled" = false;

    # Disable "Privacy Preserving Attribution API"
    "dom.private-attribution.submission.enabled" = false;
  };
}
