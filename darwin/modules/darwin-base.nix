{ config, pkgs, lib, ... }: {
  nix.settings.sandbox = false;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.settings.substituters = [
    "https://cadance.vs49688.net/cache"
  ];

  nix.settings.trusted-public-keys = [
    "cadance.vs49688,net-1:EQcyD9wxzTEdAuqCHbRZUx09b++wE7eA7VZ+7M55npU="
  ];

  nixpkgs.config.allowUnfree = true;

  documentation.man.enable = true;
  programs.man.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    home-manager
    getent
    gnupg
    pinentry_mac
    git
    texlive.combined.scheme-full
    man-pages-posix
    rustup
    wireguard-tools
    wireguard-go

    ffmpeg
    flac
    mpv
  ] ++ (with pkgs; let
    goPackage = go_1_26;
    buildGoModule = buildGo126Module;
  in [
    goPackage
    (mockgen.override  { inherit buildGoModule; })
    (gotools.override  { inherit buildGoModule; })
    (gosec.override    { inherit buildGoModule; })
    (govulncheck.override { /* inherit buildGoModule; */ })
    (delve.override { inherit buildGoModule; })
  ]);

  programs.gnupg.agent.enable = true;

  programs.bash.enable = true;
  programs.bash.completion.enable = true;

  programs.zsh.enable = true;

  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  fonts.packages = with pkgs; [
    terminus_font
    terminus_font_ttf
    corefonts
    fira-code
    fira-code-symbols
    cm_unicode
  ];

  homebrew.enable = true;
  homebrew.global.autoUpdate = false;

  homebrew.onActivation.autoUpdate = false;
  homebrew.onActivation.cleanup = "none";
  homebrew.onActivation.upgrade = false;
  homebrew.onActivation.extraFlags = [ "--verbose" ];

  homebrew.brews = [
    "cmake"
  ];

  homebrew.casks = [
    # "gimp"
    "vlc"
    "telegram"
    "thunderbird"
    "hammerspoon"
    "rectangle"
    "linearmouse"
    # "iterm2"
    "ghostty"
    "firefox"
    # "google-chrome"
    # "inkscape"
    "libreoffice"
    "lulu"
    "openmtp"
    "signal"
    "transmission"
    "vscodium"
    "alt-tab"
  ];

  environment.etc."shells".knownSha256Hashes = [
    # Default Monterey
    "9d5aa72f807091b481820d12e693093293ba33c73854909ad7b0fb192c2db193"
  ];
}
