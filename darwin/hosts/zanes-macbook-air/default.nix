{ config, lib, pkgs, ... }: let
  lowPrio = lib.mkOverride 2000;

  primaryUser = config.settings.primaryUser;
in {
  imports = [
    ../../modules/darwin-base.nix
    ../../../modules/settings
  ];

  settings.primaryUser = lowPrio "nixos";
  settings.users.nixos = lowPrio {
    fullName = "NixOS User";
    username = "nixos";
    email = "nixos@example.com";
    home = "/home/nixos";
    sshKeyPath = "~/.ssh/id_ed25519";
    gpgKeyId = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # Until the modules are updated to use darwinConfig.
  home-manager.extraSpecialArgs = { hostName = config.networking.hostName; };

  networking.hostName =  "Zanes-MacBook-Air";

  system.primaryUser = primaryUser.username;

  home-manager.users.${primaryUser.username} = import ./../../../modules/home;

  users.users.${primaryUser.username} = {
    createHome  = true;
    description = primaryUser.fullName;
    home        = primaryUser.home;
    uid         = 501; # ${primaryUser.username}
    gid         = 20;  # staff
    isHidden    = false;
    shell       = pkgs.bashInteractive;

    openssh.authorizedKeys.keys = primaryUser.authorizedKeys;
  };

  system.stateVersion = 4;
}