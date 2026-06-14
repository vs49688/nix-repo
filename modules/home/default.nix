{ osConfig, pkgs, lib, hostName, ... }:
let
  isWorkMachine = false;

  # Keeping this to allow a dispatch for isWorkMachine.
  userSettings = assert !isWorkMachine; {
    gitName       = osConfig.settings.primaryUser.fullName;
    gitEmail      = osConfig.settings.primaryUser.email;
    gitSigningKey = osConfig.settings.primaryUser.sshKeyPath;
    gitSSHUser    = osConfig.settings.primaryUser.username;
    sshKeyPath    = osConfig.settings.primaryUser.sshKeyPath;
    authorizedKeys = osConfig.settings.primaryUser.authorizedKeys;
  };
in
{
  imports = [
    ./common
    ./linux
    ./osx
  ] ++ lib.optionals isWorkMachine [
  ];

  common.gitName       = userSettings.gitName;
  common.gitEmail      = userSettings.gitEmail;
  common.gitSigningKey = userSettings.gitSigningKey;
  common.sshDefaultKey = userSettings.sshKeyPath;
  common.authorizedKeys = userSettings.authorizedKeys;

  common.goPrivate = [ "git.vs49688.net" ];

  # https://github.com/nix-community/home-manager/issues/1011
  home.file.".xprofile".text = ''
    if [ -e $HOME/.profile ]; then
      . $HOME/.profile
    fi
  '';

  programs.bash = {
    shellAliases = {
      playmidi = "${pkgs.fluidsynth}/bin/fluidsynth -q -i -m alsa_seq -c 16 -z 2048 -r 48000 ${pkgs.soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2";
    };
  };

  programs.ssh.settings = let
    mainKey = userSettings.sshKeyPath;

    defaultConfig = {
      user         = userSettings.gitSSHUser;
      identityFile = mainKey;
    };

    gitConfig = defaultConfig // { user = "git"; };

    hosts = lib.optionalAttrs (!isWorkMachine) {
      "github.com" = gitConfig;
      "codeberg.org" = gitConfig;
      "git.vs49688.net" = gitConfig;
      "code.ffmpeg.org" = gitConfig;

      "media media.vs49688.net" = {
        user         = "root";
        hostname     = "media.vs49688.net";
        identityFile = mainKey;
      };

      "candy cadance cadance.vs49688.net" = defaultConfig // {
        hostname = "cadance.vs49688.net";
      };

      "morningstar morningstar.vs49688.net" = defaultConfig // {
        hostname = "morningstar.vs49688.net";
      };
    };
  in hosts;
}
